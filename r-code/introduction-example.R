# Run the line below if BayesFluxR is not yet installed.
# install.packages("BayesFluxR")

# It is best to install Julia manually. Although BayesFluxR has the
# ability to install Julia automatically, this fails on some systems.
# Specifying the location of the Julia installation
Sys.setenv(JULIA_HOME = "/Applications/Julia-1.8.app/Contents/Resources/julia/bin/")

library(BayesFluxR)
BayesFluxR_setup(installJulia = TRUE, env_path = ".", seed = 123456)

data <- matrix(rnorm(3*1000), ncol = 3)
tensor <- tensor_embed_mat(data, len_seq = 10+1)
y <- tensor[11, 1, ]
x <- tensor[1:10, , , drop = FALSE]

# net <- Chain(LSTM(3, 10), Dense(10, 10, "relu"), Dense(10, 1))
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
