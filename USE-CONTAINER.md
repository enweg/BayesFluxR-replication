The best way to replicate the results is to use a container. For this, please first make sure that Docker is installed. If docker is not yet installed, please see the [official documentation on installing Docker](https://docs.docker.com/get-docker/). 

After installing Docker, start a new terminal in the 'BayesFluxR-replication' folder. Next, build the container using the following command. 

```
docker build -t bayesflux-replication .
```

The container is set up to provide a Julia and R environment that is compatible with ours and should therefore guarantee replication. To obtain a Julia REPL, use the following command.

```
docker run -it --rm --mount type=bind,source="$(pwd)",target=/root/BayesFluxR-replication/ bayesflux-replication julia
```

To obtain a R REPL instead, use the following command. 

```
docker run -it --rm --mount type=bind,source="$(pwd)",target=/root/BayesFluxR-replication/ bayesflux-replication r
```

For the actual replication, please follow the steps in the README. The Julia installation location is '/usr/local/julia/bin'. The 'JULIA_HOME' environment variable has already been set, so that step can be skipped during replication. 

> [!NOTE]
> All output graphs are saved in the examples directory of the 'BayesFluxR-replication' folder. Running the code in the container will overwrite the current existing graphs, since the folder is shared between host and container. 
