using Pkg; Pkg.activate("."); Pkg.instantiate();
using BayesFlux, Flux
using Distributions

net = Chain(Dense(5, 1))
net = Chain(Dense(5, 5, relu), Dense(5, 1))
net = Chain(RNN(5, 5), Dense(5, 5, sigmoid), Dense(5, 1))
net = Chain(LSTM(5, 5), LSTM(5, 3), Dense(3, 1))

nc = destruct(net)
prior = GaussianPrior(nc, 0.5f0)

like = FeedforwardNormal(nc, Gamma(2.0, 0.5))

init = InitialiseAllSame(Normal(0.0f0, 0.5f0), like, prior)