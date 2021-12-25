import numpy as np
from quanestimation import *
from qutip import *

N = 8
#initial state
psi0 = spin_coherent(0.5*N, 0.5*np.pi, 0.5*np.pi, type='ket')
psi0 = psi0.full().reshape(1, len(psi0.full()))[0]
#Hamiltonian
Lambda = 1.0
g = 0.5
h = 0.1
Jx, Jy, Jz = jmat(0.5*N)
Jx, Jy, Jz = Jx.full(), Jy.full(), Jz.full()
H0 = -Lambda*(np.dot(Jx, Jx)+g*np.dot(Jy, Jy))/N-h*Jz
dH0 = [-Lambda*np.dot(Jy, Jy)/N, -Jz]
#dissipation
decay = [[Jz,0.1]]

T = 10.0
tnum = int(200*T)
tspan = np.linspace(0.0, T, tnum)

#initial psi0 for DE, PSO and NM
psi0 = [psi0]
W = np.array([[1/3,0.0],[0.0,2/3]])
# #AD algorithm
AD_paras = {'Adam':False, 'psi0':psi0, 'max_episode':500, 'epsilon':0.01, 'beta1':0.90, 'beta2':0.99}
PSO_paras = {'particle_num':10, 'psi0':psi0, 'max_episode':[1000,100], 'c0':1.0, 'c1':2.0, 'c2':2.0, 'seed':1234}
DE_paras = {'popsize':10, 'psi0':psi0, 'max_episode':1000, 'c':1.0, 'cr':0.5, 'seed':1234}
NM_paras = {'state_num':10, 'psi0':psi0, 'max_episode':1000, 'a_r':1.0, 'a_e':2.0, 'a_c':0.5, 'a_s':0.5, 'seed':1234}
DDPG_paras = {'layer_num':4, 'layer_dim':250, 'max_episode':500, 'seed':1234}

state = StateOpt(tspan, H0, dH0, decay, W, method='AD', **AD_paras)
state.QFIM(save_file=True)
