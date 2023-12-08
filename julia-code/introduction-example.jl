using Pkg; Pkg.activate("."); Pkg.instantiate();
using BayesFlux, Flux
using Distributions, Random; Random.seed!(123456)

data = randn(Float32, 1000, 3)
tensor = make_rnn_tensor(data, 10+1)
y = tensor[end, 1, :]
x = tensor[1:end-1, :, :]

# net = Chain(LSTM(3, 10), Dense(10, 10, relu), Dense(10, 1))
net = Chain(LSTM(3, 10), Dense(10, 1))
nc = destruct(net)
like = SeqToOneNormal(nc, Gamma(2.0, 0.5))
prior = GaussianPrior(nc, 0.5f0)
init = InitialiseAllSame(Normal(0.0, 0.5), like, prior)
bnn = BNN(x, y, like, prior, init)

sampler = SGLD(;stepsize_a = 1.0f0)
ch = mcmc(bnn, 100, 10_000, sampler)
posterior_predictive_values = sample_posterior_predict(bnn, ch)

# SGLD requires only the specification of the stepsize schedule parameters
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