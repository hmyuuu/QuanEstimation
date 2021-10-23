import numpy as np
import warnings
import math
# import julia
from julia import Main
# from julia import QuanEstimation
import quanestimation.Control.Control as Control

class StateOpt_AD(Control.ControlSystem):
    def __init__(self, tspan, rho_initial, H0, Hc=[], dH=[], ctrl_initial=[], Liouville_operator=[], \
                 gamma=[], control_option=True, ctrl_bound=10.0, W=[], epsilon=1e-4, max_episodes=200, Adam=True, lr=0.01, \
                 beta1=0.90, beta2=0.99, mt=0.0, vt=0.0, precision=1e-8):

        """
        ----------
        Inputs
        ----------
        tspan:
            --description: time series.
            --type: array

        rho_initial:
            --description: initial state (density matrix).
            --type: matrix
            
        H0:
            --description: free Hamiltonian.
            --type: matrix

        Hc:
            --description: control Hamiltonian.
            --type: list (of matrix)

        dH:
            --description: derivatives of Hamiltonian on all parameters to
                                be estimated. For example, dH[0] is the derivative
                                vector on the first parameter.
            --type: list (of matrix)

        ctrl_initial:
            --description: control coefficients.
            --type: list (of array)

        Liouville operator:
            --description: Liouville operator.
            --type: list (of matrix)

        gamma:
            --description: decay rates.
            --type: list (of float number)

        W:
            --description: weight matrix.
            --type: matrix

        Adam:
            --description: whether to use Adam to update the controls.
            --type: bool (True or False)

        lr:
            --description: learning rate.
            --type: float number

        beta1, beta2, mt, vt:
            --description: Adam parameters.
            --type: float number

        precision:
            --description: calculation precision.
            --type: float number

        """
        Control.ControlSystem.__init__(self, tspan, rho_initial, H0, Hc, dH, ctrl_initial, Liouville_operator, gamma, control_option)
        self.lr = lr
        self.precision = precision
        self.max_episodes = max_episodes
        self.ctrl_bound = ctrl_bound
        self.epsilon = epsilon
        self.beta1 = beta1
        self.beta2 = beta2
        self.mt = mt
        self.vt = vt
        self.Adam = Adam
        if W == []:
            self.W = np.eye(len(dH))
        else:
            self.W = W

    def QFIM(self, save_file=False):
        """
        Description: use automatic differentiation algorithm to calculate the gradient of QFIM (QFI) and update the controls.

        ---------
        Inputs
        ---------
        save_file:
            --description: True: save all the control coefficients and quantum fisher information
                                  for single parameter estimation and the value of target function
                                  for multiparameter estimation.
                                  False: return quantum fisher information for single parameter
                                  estimation and the value of target function for multiparameter estimation.
            --type: bool

        ----------
        Returns
        ----------
            --description: updated values of control coefficients and for single parameter estimation
                                and the value of target function for multiparameter estimation.
            --type: txt file

        ----------
        Notice
        ----------
            1) maximize is always more accurate than the minimize in this code.

        """
        AD = Main.QuanEstimation.StateOpt_AD(self.freeHamiltonian, self.Hamiltonian_derivative, self.rho_initial, self.tspan, \
                        self.Liouville_operator, self.gamma, self.control_Hamiltonian, self.control_coefficients, self.ctrl_bound,\
                        self.W, self.mt, self.vt, self.lr, self.beta1, self.beta2, self.precision)

        Main.QuanEstimation.AD_QFIM(AD, self.epsilon, self.max_episodes, self.Adam, save_file)
            
    def CFIM(self, Measurement, save_file=False):
        """
        Description: use automatic differentiation algorithm to calculate the gradient of CFIM (CFI) and update the controls.

        ---------
        Inputs
        ---------
        M:
            --description: a set of POVM. It takes the form [M1, M2, ...].
            --type: list (of matrix)

        save_file:
            --description: True: save all the control coefficients and classical fisher information
                                for single parameter estimation and the value of target function
                                for multiparameter estimation.
                                False: return classical fisher information for single parameter
                                estimation and the value of target function for multiparameter estimation.
            --type: bool

        ----------
        Returns
        ----------
            --description: updated values of control coefficients and for single parameter estimation
                                  and the value of target function for multiparameter estimation.
            --type: txt file

        ----------
        Notice
        ----------
            1) maximize is always more accurate than the minimize in this code.

        """

        AD = Main.QuanEstimation.StateOpt_AD(self.freeHamiltonian, self.Hamiltonian_derivative, self.rho_initial, self.tspan, \
                        self.Liouville_operator, self.gamma, self.control_Hamiltonian, self.control_coefficients, self.ctrl_bound,\
                        self.W, self.mt, self.vt, self.lr, self.beta1, self.beta2, self.precision)
        Main.QuanEstimation.AD_CFIM(Measurement, AD, self.epsilon, self.max_episodes, self.Adam, save_file)
        