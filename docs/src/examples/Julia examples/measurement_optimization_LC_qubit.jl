using QuanEstimation
using Random
using StableRNGs
using LinearAlgebra
using DelimitedFiles

# initial state
rho0 = 0.5*ones(2, 2)
# free Hamiltonian
omega = 1.0
sx = [0. 1.; 1. 0.0im]
sy = [0. -im; im 0.]
sz = [1. 0.0im; 0. -1.]
H0 = 0.5*omega*sz
# derivative of the free Hamiltonian on omega
dH = [0.5*sz]
# dissipation
sp = [0. 1.; 0. 0.0im]
sm = [0. 0.; 1. 0.0im]
decay = [[sp, 0.], [sm, 0.1]]
# generation of a set of POVM basis
dim = size(rho0, 1)
M_num = 2
POVM_basis = QuanEstimation.SIC(dim)
# time length for the evolution
tspan = range(0., 10., length=2500)
# find the optimal linear combination of an input measurement
opt = QuanEstimation.MeasurementOpt(mtype=:LC, POVM_basis=POVM_basis, M_num=M_num, seed=1234)

##==========choose measurement optimization algorithm==========##
##-------------algorithm: DE---------------------##
alg = QuanEstimation.DE(p_num=10, ini_population=missing, 
                        max_episode=1000, c=1.0, cr=0.5)
# input the dynamics data
dynamics = QuanEstimation.Lindblad(opt, tspan ,rho0, H0, dH, decay=decay, dyn_method=:Expm)
# objective function: tr(WI^{-1})
obj = QuanEstimation.CFIM_obj()
# run the measurement optimization problem
QuanEstimation.run(opt, alg, obj, dynamics; savefile=false)
# convert the flattened data into a list of matrix
M_ = readdlm("measurements.csv",'\t', Complex{Float64})
M = [[reshape(M_[i,:], dim, dim) for i in 1:M_num] for j in 1:Int(length(M_[:,1])/M_num)][end]

##-------------algorithm: PSO---------------------##
# alg = QuanEstimation.PSO(p_num=10, ini_particle=missing, 
#                          max_episode=[1000,100], c0=1.0, c1=2.0, 
#                          c2=2.0)
# # input the dynamics data
# dynamics = QuanEstimation.Lindblad(opt, tspan ,rho0, H0, dH, decay=decay, dyn_method=:Expm)
# # objective function: tr(WI^{-1})
# obj = QuanEstimation.CFIM_obj()
# # run the measurement optimization problem
# QuanEstimation.run(opt, alg, obj, dynamics; savefile=false)
# # convert the flattened data into a list of matrix
# M_ = readdlm("measurements.csv",'\t', Complex{Float64})
# M = [[reshape(M_[i,:], dim, dim) for i in 1:M_num] for j in 1:Int(length(M_[:,1])/M_num)][end]

##-------------algorithm: AD---------------------##
# alg = QuanEstimation.AD(Adam=false, max_episode=300, epsilon=0.01, 
#                         beta1=0.90, beta2=0.99)
# # input the dynamics data
# dynamics = QuanEstimation.Lindblad(opt, tspan ,rho0, H0, dH, decay=decay, dyn_method=:Expm)
# # objective function: tr(WI^{-1})
# obj = QuanEstimation.CFIM_obj()
# # run the measurement optimization problem
# QuanEstimation.run(opt, alg, obj, dynamics; savefile=false)
# # convert the flattened data into a list of matrix
# M_ = readdlm("measurements.csv",'\t', Complex{Float64})
# M = [[reshape(M_[i,:], dim, dim) for i in 1:M_num] for j in 1:Int(length(M_[:,1])/M_num)][end]
