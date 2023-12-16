# Notes on Replications

This document provides information on replication of the paper

	BayesFlux(R): R and Julia Libraries for Bayesian Neural Network Estimation
	Rui Jorge Almeida, Nalan Bastürk, Enrico Wegner

Please clone this repository in your home directory. In Windows this is usually 
`C:\Users\yourusername\` while on unix based systems this is `~/`. If you prefer
cloning the repository into another directory, you will have to adjust paths 
in this file. 

**General Structure**

The replication folder '~/BayesFluxR-replication' contains the following three folders:

  1. 'julia-code' includes the Julia code for sections 1-3 (inclusive). See the
     section below for replication notes.
  2. 'r-code' includes the R code for sections 1-3 (inclusive). See the section
     below for replication notes. 
  3. 'examples' includes both the Julia and R code for section 4 (Example on
     simulated data)

**General Installation Notes**

To run the code chunks in the paper and to replicate section 4, BayesFlux and
BayesFluxR are needed. Thus, a basic installation of Julia and R is needed. We
recommend using Julia 1.8.5 and R 4.2.2, which are the versions that we used.
To run Julia and R, your favourite editor or IDE can be used. We used RStudio 
for R and VS-Code for Julia. 

For installation instructions of Julia and R, please follow the official
instructions on 

- Julia: https://julialang.org
- VS Code Julia: https://www.julia-vscode.org
- RStudio: https://posit.co/products/open-source/rstudio/
- R: https://www.r-project.org

After installation of Julia and R, BayesFlux and BayesFluxR can be installed. 

- R: BayesFluxR can be installed from CRAN by using 

```
install.packages("remotes")
remotes::install_github("enweg/BayesFluxR@v0.1.3")
```

- Jula: BayesFlux can be installed from the official repository using 

```
using Pkg
Pkg.add(Pkg.PackageSpec(;name="BayesFlux", version="0.2.2"))
```

Note: All running times below were measured on a MacBook Air M1


## Code for sections 1-3 (inclusive)


### Julia Code

The Julia code for sections 1-3 (inclusive) can be found in the 'julia-code'
folder. The file 'introduction-example.jl' includes the code for the
code-listings in section 1 and section 2. Code for section 3 can be found in the
'computational-implementation.jl' file. To make sure that replication is
successful, please make sure to open the .jl files within the 'julia-code' folder
such that the working directory is the 'julia-code' folder. The working
directory in Julia can also be changed using the `cd` function. So if you want
to make sure that your working directory is set right, please run the following: 

```
# Expected running time: <1s
p = joinpath(homedir(), "BayesFluxR-replication", "julia-code")
cd(p)
pwd()
```


**Running 'introduction-example.jl'**

Now that the working directory has been set, you should be able to just run the
entire file, or run it line by line. The first line of the script activates the
environment in the 'julia-code' file. It then instantiates the environment -
this should set up the entire environment including the packages needed. 


```
# Expected running time: 250s
include("introduction-example.jl")
```


**Running 'computational-implementation.jl'**

This is similar to running 'introduction-example.jl'. You should be able to just
run the entire file or run it line by line. 

```
# Expected running time: 3s
include("computational-implementation.jl")
```


### R-code

The R code for sections 1-3 (inclusive) can be found in the r-code folder. The
file 'introduction-example.R' includes the R code corresponding to section 1 and
2 and is the equivalent to 'introduction-example.jl'. The folder 'r-code' is
also an RStudio project. The best way to replicate the code is thus to open
this project in RStudio and then to run the 'introduction-example.R' file either
completely or line by line. 

Since BayesFluxR relies on BayesFlux and thus Julia, we need to link R to Julia.
The best way to do this is to use a manual installation of Julia. All that you 
then need to do is to replace the path below with the path to your already 
installed Julia executable. 

```
# It is best to install Julia manually. Although BayesFluxR has the
# ability to install Julia automatically, this fails on some systems.
# Specifying the location of the Julia installation
Sys.setenv(JULIA_HOME = "/Applications/Julia-1.8.app/Contents/Resources/julia/bin/")
```

Running BayesFluxR for the first time can take a while since the Julia
environment first needs to be set up. Please be patient here. 

```
# Expected running time: ~360s
p <- path.expand("~/BayesFluxR-replication/r-code")
setwd(p)
source("introduction-example.R")
```

```
# Expected running time: ~30s
source("computational-implementation.R")
```

## Code for section 4 (Example on simulated data)

Section 4 in the paper includes a small example on simulated AR(1) data. This
example can be both run in Julia and in R (The R code is in the appendix of the
paper). All files needed for this can be found in the 'examples' folder.
'bnn.jl' and 'bnn.R' contain respectively the Julia and R code for the Bayesian
Feedforward architecture in section 4. 'blstm.jl' and 'blstm.R' contain
respectively the Julia and R code for the Bayesian LSTM architecture in section 4. 

**Running the Julia code**

Running the Julia code is similar to above. Please make sure that the working
directory is set to the 'examples' folder. If this is not currently the case,
then please use the `cd` command as explained above. With the working directory
set to the 'examples' folder, both the 'bnn.jl' and the 'blstm.jl' files can
either be run line by line or entirely. Both files will produce the graphs used
in the paper and some additional graphs. 

```
# Expected running time: <1s
p = joinpath(homedir(), "BayesFluxR-replication", "examples")
cd(p)
```

```
# Expected running time: 75s
include("bnn.jl")
```

```
# Expected running time: 30s
include("blstm.jl")
```

If you also want to replicate the data simulation, you can do so by running 
'data-simulation.jl'. This is not a necessary step, since both the R and the 
Julia code in the 'examples' directory load pre-simualated data saved in the 
'data_ar1.jld' file. 

**Running the R code**

The 'examples' folder is itself an RStudion project. The best way to replicate
the results is thus to open this project in RStudio. The first step is then to
point R to the Julia installation by changing the path below. 

```
# It is best to install Julia manually. Although BayesFluxR has the
# ability to install Julia automatically, this fails on some systems.
# Specifying the location of the Julia installation
Sys.setenv(JULIA_HOME = "/Applications/Julia-1.8.app/Contents/Resources/julia/bin/")
```

The code below will produce graphs equivalent to the Julia graphs, but does not 
save these, because the Julia graphs were used for the paper. 

```
# Expected running time: ~120s
p <- path.expand("~/BayesFluxR-replication/examples")
setwd(p)
source("bnn.R")
```

```
# Expected running time: ~60s
source("blstm.R")
```

## Problems? 

If problems or questions arise, please contact Enrico Wegner:
 - e.wegner@maastrichtuniversity.nl
