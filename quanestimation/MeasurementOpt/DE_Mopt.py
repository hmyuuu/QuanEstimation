import numpy as np
from julia import Main
import quanestimation.MeasurementOpt.MeasurementStruct as Measurement


class DE_Mopt(Measurement.MeasurementSystem):
    def __init__(
        self,
        mtype,
        minput,
        popsize=10,
        measurement0=[],
        max_episode=1000,
        c=1.0,
        cr=0.5,
        seed=1234,
        load=False,
    ):

        Measurement.MeasurementSystem.__init__(
            self, mtype, minput, measurement0, seed, load, eps=1e-8
        )

        """
        --------
        inputs
        --------
        popsize:
           --description: the number of populations.
           --type: int
        
        measurement0:
           --description: initial guesses of measurements.
           --type: array

        max_episode:
            --description: max number of the training episodes.
            --type: int
        
        c:
            --description: mutation constant.
            --type: float

        cr:
            --description: crossover constant.
            --type: float
        
        seed:
            --description: random seed.
            --type: int
        
        """
        self.popsize = popsize
        self.max_episode = max_episode
        self.c = c
        self.cr = cr

    def CFIM(self, W=[], save_file=False):
        """
        Description: use differential evolution algorithm to update the measurements that maximize the
                     CFI (1/Tr(WF^{-1} with F the CFIM).

        ---------
        Inputs
        ---------
        save_file:
            --description: True: save the measurements for each episode but overwrite in the next episode and all the CFI (Tr(WF^{-1})).
                           False: save the measurements for the last episode and all the CFI (Tr(WF^{-1})).
            --type: bool
        """
        if self.mtype == "projection":
            if self.dynamics_type == "dynamics":
                if W == []:
                    W = np.eye(len(self.Hamiltonian_derivative))
                self.W = W

                diffevo = Main.QuanEstimation.projection_Mopt(
                    self.freeHamiltonian,
                    self.Hamiltonian_derivative,
                    self.rho0,
                    self.tspan,
                    self.decay_opt,
                    self.gamma,
                    self.M,
                    self.W,
                    self.eps,
                )
                Main.QuanEstimation.CFIM_DE_Mopt(
                    diffevo,
                    self.popsize,
                    self.measurement0,
                    self.c,
                    self.cr,
                    self.seed,
                    self.max_episode,
                    save_file,
                )

            elif self.dynamics_type == "kraus":
                if W == []:
                    W = np.eye(len(self.dK))
                self.W = W

                diffevo = Main.QuanEstimation.projection_Mopt_Kraus(
                    Main.vec(self.K),
                    Main.vec(self.dK),
                    self.rho0,
                    self.M,
                    self.W,
                    self.eps,
                )
                Main.QuanEstimation.CFIM_DE_Mopt(
                    diffevo,
                    self.popsize,
                    self.measurement0,
                    self.c,
                    self.cr,
                    self.seed,
                    self.max_episode,
                    save_file,
                )

            self.load_save()

        elif self.mtype == "input":
            if self.dynamics_type == "dynamics":
                if W == []:
                    W = np.eye(len(self.Hamiltonian_derivative))
                self.W = W

                diffevo = Main.QuanEstimation.LinearComb_Mopt(
                    self.freeHamiltonian,
                    self.Hamiltonian_derivative,
                    self.rho0,
                    self.tspan,
                    self.decay_opt,
                    self.gamma,
                    self.povm_basis,
                    self.M_num,
                    self.W,
                    self.eps,
                )
                Main.QuanEstimation.CFIM_DE_Mopt(
                    diffevo,
                    self.popsize,
                    self.c,
                    self.cr,
                    self.seed,
                    self.max_episode,
                    save_file,
                )
            elif self.dynamics_type == "kraus":
                if W == []:
                    W = np.eye(len(self.dK))
                self.W = W

                diffevo = Main.QuanEstimation.LinearComb_Mopt_Kraus(
                    Main.vec(self.K),
                    Main.vec(self.dK),
                    self.rho0,
                    self.povm_basis,
                    self.M_num,
                    self.W,
                    self.eps,
                )
                Main.QuanEstimation.CFIM_DE_Mopt(
                    diffevo,
                    self.popsize,
                    self.c,
                    self.cr,
                    self.seed,
                    self.max_episode,
                    save_file,
                )

            self.load_save()

        elif self.mtype == "rotation":
            if self.dynamics_type == "dynamics":
                if W == []:
                    W = np.eye(len(self.Hamiltonian_derivative))
                self.W = W

                diffevo = Main.QuanEstimation.RotateBasis_Mopt(
                    self.freeHamiltonian,
                    self.Hamiltonian_derivative,
                    self.rho0,
                    self.tspan,
                    self.decay_opt,
                    self.gamma,
                    self.povm_basis,
                    self.W,
                    self.eps,
                )
                Main.QuanEstimation.CFIM_DE_Mopt(
                    diffevo,
                    self.popsize,
                    self.c,
                    self.cr,
                    self.seed,
                    self.max_episode,
                    save_file,
                )
            elif self.dynamics_type == "kraus":
                if W == []:
                    W = np.eye(len(self.dK))
                self.W = W

                diffevo = Main.QuanEstimation.RotateBasis_Mopt_Kraus(
                    Main.vec(self.K),
                    Main.vec(self.dK),
                    self.rho0,
                    self.povm_basis,
                    self.W,
                    self.eps,
                )
                Main.QuanEstimation.CFIM_DE_Mopt(
                    diffevo,
                    self.popsize,
                    self.c,
                    self.cr,
                    self.seed,
                    self.max_episode,
                    save_file,
                )
            self.load_save()
        else:
            raise ValueError(
                "{!r} is not a valid value for mtype, supported values are 'projection' and 'input'.".format(
                    self.mtype
                )
            )
