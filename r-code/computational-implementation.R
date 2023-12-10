library(BayesFluxR)
BayesFluxR_setup(installJulia = TRUE, env_path = ".", seed = 123456)

net <- Chain(Dense(5, 1))
net <- Chain(Dense(5, 5, "relu"), Dense(5, 1))
net <- Chain(RNN(5, 5), Dense(5, 5, "sigmoid"), Dense(5, 1))
net <- Chain(LSTM(5, 5), LSTM(5, 3), Dense(3, 1))

prior <- prior.gaussian(net, 0.5)
like <- likelihood.feedforward_normal(net, Gamma(2.0, 0.5))
init <- initialise.allsame(Normal(0, 0.5), like, prior)
