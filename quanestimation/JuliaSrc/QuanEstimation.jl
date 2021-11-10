module QuanEstimation

# using LinearAlgebra: similar
using LinearAlgebra
using Zygote
using DifferentialEquations
using JLD
using Random
using SharedArrays
using Base.Threads
using SparseArrays
using DelimitedFiles
using StatsBase
using ReinforcementLearning

include("AsymptoticBound/CramerRao.jl")
include("Common/common.jl")
include("Common/utils.jl")
include("Control/GRAPE.jl")
include("Control/DDPG.jl")
include("Control/PSO.jl")
include("Control/DiffEvo.jl")
include("Control/common.jl")
include("Dynamics/dynamcs.jl")
include("StateOptimization/StateOpt_DE.jl")
include("StateOptimization/StateOpt_NM.jl")
include("StateOptimization/StateOpt_PSO.jl")
include("StateOptimization/StateOpt_AD.jl")
include("StateOptimization/common.jl")
# include("QuanResources/")

export sigmax, sigmay, sigmaz, sigmam, sigmap, vec2mat
export Gradient, evolute, propagate!, propagate, QFI, CFI, gradient_CFI!,gradient_QFIM!
export GRAPE_QFIM_auto, GRAPE_CFIM_auto, GRAPE_QFIM_ana,GRAPE_CFIM_ana, RunODE, RunMixed, RunPSO
export DDPG_QFIM, DDPG, ControlEnvParams

end
