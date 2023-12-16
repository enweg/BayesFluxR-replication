# Loading BayesFluxR and setting up
library(BayesFluxR)
BayesFluxR_setup(installJulia = TRUE, env_path = ".", seed = 6150533)
library(JuliaCall)

# Loading the AR(1) data created in Julia
JuliaCall::julia_library("Serialization")
data <- JuliaCall::julia_eval('deserialize("./data_ar1.jld")')
y <- data
y <- tensor_embed_mat(matrix(y, ncol = 1), len_seq = 5 + 1)
x <- y[1:5, , , drop = FALSE]
y <- y[6, , ]
y_train <- y[1:500]
y_test <- y[501:length(y)]
x_train <- x[, , 1:500, drop = FALSE]
x_test <- x[, , 501:dim(x)[3], drop = FALSE]

net <- Chain(LSTM(1, 1), Dense(1, 1))
prior <- prior.gaussian(net, 0.8)
like <- likelihood.seqtoone_normal(net, Gamma(2.0, 0.5))
init <- initialise.allsame(Normal(0.0, 0.5), like, prior)
bnn <- BNN(x_train, y_train, like, prior, init)

summary(bnn)

.set_seed(6150533)
sampler <- sampler.SGNHTS(1e-2, sigmaA = 1, xi = 1, mu = 10)
ch <- mcmc(bnn, 10, 50000, sampler)
ch <- ch$samples
ch <- ch[, (ncol(ch)-20000+1):ncol(ch)]

# trace plots for draws
end <- dim(ch)[1]
draws_sigma <- exp(ch[end,])
pdf(file = "./blstm-trace-sigma-R.pdf", width=10, height=8)
plot(1:length(draws_sigma), draws_sigma, type = "l", xlab = "", ylab = "sigma")
dev.off()
pdf(file = "./blstm-trace-bad-R.pdf", width=10, height=8)
plot(1:length(draws_sigma), ch[1, ], type = "l", xlab = "", ylab = "")
dev.off()
pdf(file = "./blstm-trace-better-R.pdf", width=10, height=8)
plot(1:length(draws_sigma), ch[end-1, ], type = "l", xlab = "", ylab = "")
dev.off()
pdf(file = "./blstm-trace-predicted-R.pdf", width=10, height=8)
ch_zero_sigma <- ch
ch_zero_sigma[end, ] <- log(0)
ys = posterior_predictive(bnn, ch_zero_sigma, x = x_train)
plot(1:dim(ys)[2], ys[90, ], type = "l", xlab = "", ylab = "")
dev.off()

# Using bayesplot
ys <- to_bayesplot(ys, "y")
library(bayesplot)
mcmc_areas(ys,
           pars = paste0("y", 1:10),
           prob = 0.8)
end = dim(ys)[1]
pdf(file = "./blstm-ppc-dens-overlay-R.pdf")
bayesplot::ppc_dens_overlay(y = y_train, yrep = ys[(end-100):end, 1, ])
dev.off()
library(rstan)
rhats <- apply(ys, 3, rstan::Rhat)
ess <- apply(ys, 3, rstan::ess_bulk)

# posterior predictive
ypp <- posterior_predictive(bnn, ch, x = x_test)
ypp_mean <- apply(ypp, 1, mean)
qs <- apply(ypp, 1, function(x) quantile(x, 0.05))

pdf(file="./blstm-posterior-predictive-R.pdf", width=10, height=8)
plot(y_test, type = "l", col = "black", xlab = "", ylab = "")
lines(ypp_mean, type = "l", col = "red")
lines(qs, lty = 2, col = "red")
legend(x = 300, y = 4, legend = c("Test Data", "Posterior Predictive Mean", "5% Predictive Quantile"),
       col = c("black", "red", "red"),
       lty = c(1, 1, 2))
dev.off()

# How many % of test data fall below 5% quantile?
mean(y_test < qs)

pdf(file="./blstm-posterior-prior-R.pdf", width=10, height=8)
y_prior <- prior_predictive(bnn, 20000)
i <- 110
dprior <- density(y_prior[i, ])
dposterior <- density(ypp[i, ])
plot(dprior, ylim=range(dprior$y, dposterior$y), col = "blue", xlab = "", ylab = "", main = "")
lines(dposterior, col = "red")
legend(x = 2.5, y = 0.4, legend = c("prior", "posterior"),
       col = c("blue", "red"),
       lty = c(1, 1))
dev.off()
