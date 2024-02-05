# Notes on Replications

This document provides information on replication of the paper

	BayesFlux(R): R and Julia Libraries for Bayesian Neural Network Estimation
	Rui Jorge Almeida, Nalan Bastürk, Enrico Wegner

Please clone this repository in your home directory. In Windows this is usually 
`C:\Users\yourusername\` while on unix based systems this is `~/`. If you prefer
cloning the repository into another directory, you will have to adjust paths 
in this file. 

**General Structure**

The replication folder '~/BayesFluxR-replication' contains the following folders:

1. 'replication-julia' includes the 'replication.jl' file, which is the file
   used to replicate all julia results. It also includes 'data-simulation.jl', 
   which is used to simulate data. This file does not need to be run. The 
   simulated data is already contained in 'data_ar1.jld'.
2. 'replication-r' includes the 'replication.R' file, which is the file used
   to replicate all R results. It also includes 'data_simulation.jl' and 
   'data_at1.jld', which are the same files as in the 'replication-julia' folder.
   'data_simulation.jl' does not need to be run. The simulation data is already
   stored in 'data_ar1.jld'. 

**General Installation Notes**

To run the code chunks in the paper and to replicate the results, BayesFlux and
BayesFluxR are needed. Thus, a basic installation of Julia and R is needed. We
recommend using Julia 1.9.4 and R 4.3.1, which are the versions that we used.
To run Julia and R, your favourite editor or IDE can be used. We used RStudio 
for R and VS-Code for Julia. 

For installation instructions of Julia and R, please follow the official
instructions on 

- Julia: https://julialang.org
- VS Code Julia: https://www.julia-vscode.org
- RStudio: https://posit.co/products/open-source/rstudio/
- R: https://www.r-project.org

After installation of Julia and R, BayesFlux and BayesFluxR can be installed. 

- R: BayesFluxR can be installed using (This installs the version we used for the paper).

```
install.packages("remotes")
remotes::install_github("enweg/BayesFluxR@v0.1.3")
```

We recommend setting the 'JULIA_HOME' environment variable to the path of the 
manual Julia installation. This is the best way to replicate the findings using 
BayesFluxR, since some environments do not allow automatic installation of Julia.  

- Julia: BayesFlux can be installed from the official repository using (This again
uses the version that we used for the paper). 

```
using Pkg
Pkg.add(Pkg.PackageSpec(;name="BayesFlux", version="0.2.3"))
```

Note: All running times were measured on a MacBook Air M1

## Replication 

- To replicate the Julia results, use the 'replication-julia/replication.jl' file. 
- To replicate the R results, use the 'replication-r/replication.R' file.

## Problems? 

If problems or questions arise, please contact Enrico Wegner:
 - e.wegner@maastrichtuniversity.nl
