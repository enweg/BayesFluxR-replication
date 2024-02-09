# if you manually installed Julia, which is the recommended way, then
# set the JULIA_HOME environment variable to the path of you Julia installation.
Sys.setenv(JULIA_HOME = "/Applications/Julia-1.9.app/Contents/Resources/julia/bin/")

install.packages("JuliaCall")
library(BayesFluxR)
library(JuliaCall)

################################################################################
# Setup
# Please make sure to set the working directory to the 'replication-R' folder.
# If you cloned the replication reposity to your home directory, then the
# following code will set the correct working directory.
#
# Info: All running times below were measured on a MacBook Air M1
################################################################################
p <- path.expand("~/BayesFluxR-replication/replication-r")
setwd(p)
BayesFluxR_setup(installJulia = TRUE, env_path = ".", seed = 123456)



################################################################################
# Introduction Section
# Entire section needs about 360 seconds to run.
################################################################################

data <- matrix(rnorm(3*1000), ncol = 3)
tensor <- tensor_embed_mat(data, len_seq = 10+1)
y <- tensor[11, 1, ]
x <- tensor[1:10, , , drop = FALSE]

net <- Chain(LSTM(3, 10), Dense(10, 1))
like <- likelihood.seqtoone_normal(net, Gamma(2.0, 0.5))
prior <- prior.gaussian(net, 0.5)
init <- initialise.allsame(Normal(0, 0.5), like, prior)
bnn <- BNN(x, y, like, prior, init)

sampler <- sampler.SGLD(stepsize_a = 1.0)
ch <- mcmc(bnn, 100, 10000, sampler)
posterior_predictive_values <- posterior_predictive(bnn, ch$samples)

# Sampling using SGLD
sampler <- sampler.SGLD(stepsize_a = 1.0, stepsize_b = 0,
                        stepsize_gamma = 0.55)
# Sampling using minibatches of size 100 and sampling 10000 draws.
chain <- mcmc(bnn, 100, 10000, sampler)

# Sampling using SGNHTS
sampler <- sampler.SGNHTS(1e-2, sigmaA = 10, mu = 1)
chain <- mcmc(bnn, 100, 10000, sampler)

# Sampling using GGMC; BFluxR allows for mass and stepsize adaptation.
madapter <- madapter.FixedMassMatrix()
sadapter <- sadapter.DualAverage(adapt_steps = 1000,
                                 initial_stepsize = 1e-5)
sampler <- sampler.GGMC(beta = 0.5, l = 1e-5, sadapter = sadapter,
                        madapter = madapter, steps = 3)
chain <- mcmc(bnn, 100, 10000, sampler)

# Bayes-By-Backprop using minibatches of size 100 and
# running for 1000 epochs
vi <- bayes_by_backprop(bnn, 100, 1000)
chain <- vi.get_samples(vi, n = 10000)

################################################################################
# Computational Implementation Section
# Entire section needs about 30 seconds to run.
################################################################################

net <- Chain(Dense(5, 1))
net <- Chain(Dense(5, 5, "relu"), Dense(5, 1))
net <- Chain(RNN(5, 5), Dense(5, 5, "sigmoid"), Dense(5, 1))
net <- Chain(LSTM(5, 5), LSTM(5, 3), Dense(3, 1))

prior <- prior.gaussian(net, 0.5)
like <- likelihood.feedforward_normal(net, Gamma(2.0, 0.5))
init <- initialise.allsame(Normal(0, 0.5), like, prior)

################################################################################
# Examples Section: BNN
# Entire section needs about 120 seconds to run.
################################################################################

# Loading the AR(1) data created in Julia
JuliaCall::julia_library("Serialization")
data <- JuliaCall::julia_eval('deserialize("./data_ar1.jld")')
y <- data
x <- embed(y, 6)
x <- t(x[, 6:2])
y <- y[6:length(y)]
y_train <- y[1:500]
y_test <- y[501:length(y)]
x_train <- x[,1:500]
x_test <- x[,501:ncol(x)]

net <- Chain(Dense(5, 5, "relu"), Dense(5, 1))
prior <- prior.gaussian(net, 0.8)
like <- likelihood.feedforward_normal(net, Gamma(2.0, 0.5))
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
pdf(file = "./bnn-trace-sigma-R.pdf", width=10, height=8)
plot(1:length(draws_sigma), draws_sigma, type = "l", xlab = "", ylab = "sigma")
dev.off()
pdf(file = "./bnn-trace-bad-R.pdf", width=10, height=8)
plot(1:length(draws_sigma), ch[1, ], type = "l", xlab = "", ylab = "")
dev.off()
pdf(file = "./bnn-trace-better-R.pdf", width=10, height=8)
plot(1:length(draws_sigma), ch[end-1, ], type = "l", xlab = "", ylab = "")
dev.off()
pdf(file = "./bnn-trace-predicted-R.pdf", width=10, height=8)
ch_zero_sigma <- ch
ch_zero_sigma[end, ] <- log(0)
ys = posterior_predictive(bnn, ch_zero_sigma, x = x_train)
plot(1:dim(ys)[2], ys[90, ], type = "l", xlab = "", ylab = "")
dev.off()

# Using bayesplot
ys <- to_bayesplot(ys, "y")
# install.packages("bayesplot")
library(bayesplot)
# mcmc_areas(ys,
#            pars = paste0("y", 1:10),
#            prob = 0.8)
end <- dim(ys)[1]
pdf(file = "bnn-ppc-dens-overlay-R.pdf")
bayesplot::ppc_dens_overlay(y = y_train, yrep = ys[(end-100):end, 1, ])
dev.off()
# install.packages("rstan")
library(rstan)
rhats <- apply(ys, 3, rstan::Rhat)
ess <- apply(ys, 3, rstan::ess_bulk)

# posterior predictive
pdf(file="./bnn-posterior-predictive-R.pdf", width=10, height=8)
ypp <- posterior_predictive(bnn, ch, x = x_test)
ypp_mean <- apply(ypp, 1, mean)
qs <- apply(ypp, 1, function(x) quantile(x, 0.05))

plot(y_test, type = "l", col = "black", xlab = "", ylab = "")
lines(ypp_mean, type = "l", col = "red")
lines(qs, lty = 2, col = "red")
legend(x = 300, y = 4,
       legend = c("Test Data", "Posterior Predictive Mean", "5% Predictive Quantile"),
       col = c("black", "red", "red"),
       lty = c(1, 1, 2))

# How many % of test data fall below 5% quantile?
mean(y_test < qs)
dev.off()

pdf(file="./bnn-posterior-prior-R.pdf", width=10, height=8)
y_prior <- prior_predictive(bnn, 20000)
i <- 110
dprior <- density(y_prior[i, ])
dposterior <- density(ypp[i, ])
plot(dprior, ylim=range(dprior$y, dposterior$y), col = "blue", xlab = "", ylab = "", main = "")
lines(dposterior, col = "red")
legend(x = 20, y = 0.35, legend = c("prior", "posterior"),
       col = c("blue", "red"),
       lty = c(1, 1))
dev.off()

################################################################################
# Examples Section: BLSTM
# Entire section needs about 120 seconds to run.
################################################################################

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
# mcmc_areas(ys,
#            pars = paste0("y", 1:10),
#            prob = 0.8)
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
