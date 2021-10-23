import numpy as np
from julia import Main
import quanestimation.Control.Control as Control

class StateOpt_DE(Control.ControlSystem):
    def __init__(self, tspan, rho_initial, H0, Hc=[], dH=[], ctrl_initial=[], Liouville_operator=[], \
                gamma=[], control_option=True, ctrl_bound=1.0, W=[], popsize=10, ini_population=[], c=0.5, c0=0.1, \
                c1=0.6, seed=1234, max_episodes=200):
        
        """
        --------
        inputs
        --------
        particle_num:
           --description: number of particles.
           --type: float
        
        particle_num:
           --description: number of particles.
           --type: float
        
        """
        Control.ControlSystem.__init__(self, tspan, rho_initial, H0, Hc, dH, ctrl_initial, Liouville_operator, \
                                       gamma, control_option)
        self.popsize = popsize
        self.ini_population = ini_population
        self.ctrl_bound = ctrl_bound
        self.c = c
        self.c0 = c0
        self.c1 = c1
        self.seed = seed
        self.max_episodes = max_episodes
        if W == []:
            self.W = np.eye(len(dH))
        else:
            self.W = W

    def QFIM(self, save_file):
        diffevo = Main.QuanEstimation.StateOpt_DE(self.freeHamiltonian, self.Hamiltonian_derivative, self.rho_initial, self.tspan, \
                        self.Liouville_operator, self.gamma, self.control_Hamiltonian, self.control_coefficients, self.ctrl_bound, self.W)
        if len(self.Hamiltonian_derivative) == 1:
            Main.QuanEstimation.DiffEvo_QFI(diffevo, self.popsize, self.ini_population, self.c, self.c0, self.c1, self.seed, self.max_episodes, save_file)
        else:
            Main.QuanEstimation.DiffEvo_QFIM(diffevo, self.popsize, self.ini_population, self.c, self.c0, self.c1, self.seed, self.max_episodes, save_file)

    def CFIM(self, M, save_file):
        diffevo = Main.QuanEstimation.StateOpt_DE(self.freeHamiltonian, self.Hamiltonian_derivative, self.rho_initial, self.tspan, \
                        self.Liouville_operator, self.gamma, self.control_Hamiltonian, self.control_coefficients, self.ctrl_bound, self.W)
        if len(self.Hamiltonian_derivative) == 1:
            Main.QuanEstimation.DiffEvo_CFI(M, diffevo, self.popsize, self.ini_population, self.c, self.c0, self.c1, self.seed, self.max_episodes, save_file)
        else:
            Main.QuanEstimation.DiffEvo_CFIM(M, diffevo, self.popsize, self.ini_population, self.c, self.c0, self.c1, self.seed, self.max_episodes, save_file)
            