using Pkg; Pkg.activate("."); Pkg.instantiate();
using BayesFlux, Flux
using Distributions, Random; 
using Serialization
using StatsPlots
using Bijectors

################################################################################
# Setup
# Please make sure to set the working directory to the 'replication-julia' folder.
# If you cloned the replication reposity to your home directory, then the 
# following code will set the correct working directory. 
#
# Info: All running times below were measured on a MacBook Air M1
################################################################################

p = joinpath(homedir(), "BayesFluxR-replication", "julia-code")
cd(p)
pwd()

################################################################################
# Introduction Section
# Entire section needs about 250 second to run.
################################################################################

Random.seed!(123456)

data = randn(Float32, 1000, 3)
tensor = make_rnn_tensor(data, 10+1)
y = tensor[end, 1, :]
x = tensor[1:end-1, :, :]

net = Chain(LSTM(3, 10), Dense(10, 1))
nc = destruct(net)
like = SeqToOneNormal(nc, Gamma(2.0, 0.5))
prior = GaussianPrior(nc, 0.5f0)
init = InitialiseAllSame(Normal(0.0, 0.5), like, prior)
bnn = BNN(x, y, like, prior, init)

sampler = SGLD(;stepsize_a = 1.0f0)
ch = mcmc(bnn, 100, 10_000, sampler)
posterior_predictive_values = sample_posterior_predict(bnn, ch)

sampler = SGLD(; stepsize_a = 1.0f0, stepsize_b = 0.0f0, stepsize_γ = 0.55f0)
# Using minibatches of size 100 and taking 10_000 draws
chain = mcmc(bnn, 100, 10_000, sampler)

# Sampling using SGNHTS
l = 1f-2
σ_A = 10f0
μ = 1.0f0
sampler = SGNHTS(l, σ_A; μ = μ)
chain = mcmc(bnn, 100, 10_000, sampler)

# Sampling using GGMC 
# BFlux implements Mass and stepsize adaptation
madapter = FixedMassAdapter()
sadapter = DualAveragingStepSize(1f-5; adapt_steps = 1000)
sampler = GGMC(Float32; β = 0.5f0, l = 1f-5, sadapter = sadapter,
               madapter = madapter, steps = 3)
chain = mcmc(bnn, 100, 10_000, sampler)

# Bayes-By-Backprop
# Running BBB using minibatches of size 100 for 1000 epochs
vi = bbb(bnn, 100, 1_000)
# Sampling 10_000 samples from the variational distribution 
chain = rand(vi[1], 10_000)

################################################################################
# Computational Implementation Section
# Entire section needs about 3 second to run.
################################################################################

net = Chain(Dense(5, 1))
net = Chain(Dense(5, 5, relu), Dense(5, 1))
net = Chain(RNN(5, 5), Dense(5, 5, sigmoid), Dense(5, 1))
net = Chain(LSTM(5, 5), LSTM(5, 3), Dense(3, 1))

nc = destruct(net)
prior = GaussianPrior(nc, 0.5f0)

like = FeedforwardNormal(nc, Gamma(2.0, 0.5))

init = InitialiseAllSame(Normal(0.0f0, 0.5f0), like, prior)

################################################################################
# Examples Section: BNN
# Entire section needs about 75 second to run. 
################################################################################

data = deserialize("./data_ar1.jld")
y = data
x = reduce(hcat, [y[i-5:i-1] for i=6:size(y, 1)])
y = y[6:end]
x_train, x_test = x[:, 1:500], x[:, 501:end]
y_train, y_test = y[1:500], y[501:end]

net = Chain(Dense(5, 5, relu), Dense(5, 1))
nc = destruct(net)
prior = GaussianPrior(nc, 0.8f0)
like = FeedforwardNormal(nc, Gamma(2.0, 0.5))
init = InitialiseAllSame(Normal(0.0f0, 0.5f0), like, prior)
bnn = BNN(x_train, y_train, like, prior, init)

Random.seed!(6150533)
sampler = SGNHTS(1f-2, 1f0; xi = 1f0^2, μ = 10f0)
ch = mcmc(bnn, 10, 50_000, sampler)
ch = ch[:, end-20_000+1:end]

# plotting trace plots
draws_sigma = invlink.(like.prior_σ, ch[end, :])
plot(draws_sigma, label="σ")
savefig("./bnn-trace-sigma.pdf")
plot(ch[1, :], label="")
savefig("./bnn-trace-bad.pdf")
plot(ch[end-1, :], label="")
savefig("./bnn-trace-better.pdf")
ch_zero_sigma = copy(ch)
ch_zero_sigma[end, :] .= Bijectors.link(like.prior_σ, 0)
ys = sample_posterior_predict(bnn, ch_zero_sigma; x = x_train)
plot(ys[90, :] , label="")
savefig("./bnn-trace-predicted.pdf")

using MCMCChains
chain = MCMCChains.Chains(ys')
MCMCChains.ess_rhat(chain)

ypp = sample_posterior_predict(bnn, ch; x = x_test)
ypp_mean = mean(ypp; dims = 2)
qs = [quantile(x, 0.05) for x in eachrow(ypp)]
plot(qs; label = "5% predicted quantile", color = :red, linestyle = :dash)
plot!(ypp_mean; label = "Posterior Predictive Mean", color = :red)
plot!(y_test; label = "Test data", color = :black)
savefig("./bnn-posterior-predictive.pdf")

# How many test observations fall below the 5% quantile? 
mean(y_test .< qs)

predict(net) = vec(net(x_test))
y_prior = sample_prior_predictive(bnn, predict, 20_000)
y_prior = reduce(hcat, y_prior)

i = 110  # Observation for which we plot densities
density(y_prior[i,:]; label = "prior")
density!(ypp[i,:]; label = "posterior")
savefig("./bnn-posterior-and-prior.pdf")

################################################################################
# Examples Section: BLSTM
# Entire section needs about 75 seconds to run. 
################################################################################

data = deserialize("./data_ar1.jld")
y = data
x = make_rnn_tensor(reshape(y, :, 1), 5 + 1)
y = vec(x[end,:,:])
y_train, y_test = y[1:500], y[501:end]
x = x[1:end-1,:,:]
x_train, x_test = x[:,:,1:500], x[:,:,501:end]

net = Chain(LSTM(1, 1), Dense(1, 1))  # last layer is linear output layer
nc = destruct(net)
prior = GaussianPrior(nc, 0.8f0)
like = SeqToOneNormal(nc, Gamma(2.0, 0.5))
init = InitialiseAllSame(Normal(0.0f0, 0.5f0), like, prior)
bnn = BNN(x_train, y_train, like, prior, init)

Random.seed!(6150533)
sampler = SGNHTS(1f-2, 1f0; xi = 1f0^2, μ = 10f0)
ch = mcmc(bnn, 10, 50_000, sampler)
ch = ch[:, end-20_000+1:end]

# traceplot of draws
draws_sigma = invlink.(like.prior_σ, ch[end, :])
plot(draws_sigma, label="σ")
savefig("./blstm-trace-sigma.pdf")
plot(ch[1, :], label="")
savefig("./blstm-trace-bad.pdf")
plot(ch[end-1, :], label="")
savefig("./blstm-trace-better.pdf")
ch_zero_sigma = copy(ch)
ch_zero_sigma[end, :] .= Bijectors.link(like.prior_σ, 0)
ys = sample_posterior_predict(bnn, ch_zero_sigma; x = x_train)
plot(ys[90, :] , label="")
savefig("./blstm-trace-predicted.pdf")

using MCMCChains
chain = MCMCChains.Chains(ys')
MCMCChains.ess_rhat(chain)

ypp = sample_posterior_predict(bnn, ch; x = x_test)
ypp_mean = mean(ypp; dims = 2)
qs = [quantile(x, 0.05) for x in eachrow(ypp)]

plot(qs; label = "5% predicted quantile", color = :red, linestyle = :dash)
plot!(ypp_mean; label = "Posterior Predictive Mean", color = :red)
plot!(y_test; label = "Test data", color = :black)
savefig("./blstm-posterior-predictive.pdf")

# What % of test points falls below 5% quantle? 
mean(y_test .< qs)

predict(net) = vec([net(xx) for xx in eachslice(x_test; dims=1)][end])
y_prior = sample_prior_predictive(bnn, predict, 20_000)
y_prior = reduce(hcat, y_prior)

i = 110  # Observation for which we plot densities
density(y_prior[i,:]; label = "prior")
density!(ypp[i,:]; label = "posterior")
savefig("./blstm-posterior-and-prior.pdf")



