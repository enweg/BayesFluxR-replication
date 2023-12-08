using Pkg; Pkg.activate("."); Pkg.instantiate(); # Pkg.add(["Distributions", "Serialization", "BayesFlux", "StatsPlots"]);
using BayesFlux
using Flux
using Distributions
using Random
using Serialization
using StatsPlots
using Bijectors

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

