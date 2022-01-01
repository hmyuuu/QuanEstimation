import numpy as np
import os
import quanestimation.MeasurementOpt as Measure
from quanestimation.Common.common import gramschmidt, sic_povm

class MeasurementSystem:
    def __init__(self, mtype, mgiven, tspan, rho0, H0, dH, decay, W, measurement0, seed, accuracy):
        
        """
        ----------
        Inputs
        ----------
        tspan: 
           --description: time series.
           --type: array
        
        rho0: 
           --description: initial state (density matrix).
           --type: matrix
        
        H0: 
           --description: free Hamiltonian.
           --type: matrix or a list of matrix
        
        dH: 
           --description: derivatives of Hamiltonian on all parameters to
                          be estimated. For example, dH[0] is the derivative
                          vector on the first parameter.
           --type: list (of matrix)
           
        decay:
           --description: decay operators and the corresponding decay rates.
                          decay[0][0] represent the first decay operator and
                          decay[0][1] represent the corresponding decay rate.
           --type: list 
        
        measurement0:
           --description: a set of POVMs.
           --type: list (of vector)

        W:
            --description: weight matrix.
            --type: matrix

        accuracy:
            --description: calculation accuracy.
            --type: float

        notes: the Weyl-Heisenberg covariant SIC-POVM fiducial state of dimension $d$ 
               are download from http://www.physics.umb.edu/Research/QBism/solutions.html.
        
        """   
        self.mtype = mtype
        self.mgiven = mgiven
        self.tspan = tspan
        self.rho0 = np.array(rho0, dtype=np.complex128)

        if type(H0) == np.ndarray:
            self.freeHamiltonian = np.array(H0, dtype=np.complex128)
        else:
            self.freeHamiltonian = [np.array(x, dtype=np.complex128) for x in H0] 

        if type(dH) != list:
            raise TypeError('The derivative of Hamiltonian should be a list!') 

        if dH == []:
            dH = [np.zeros((len(self.rho0), len(self.rho0)))]
        self.Hamiltonian_derivative = [np.array(x, dtype=np.complex128) for x in dH]
        
        if decay == []:
            decay_opt = [np.zeros((len(self.rho0), len(self.rho0)))]
            self.gamma = [0.0]
        else:
            decay_opt = [decay[i][0] for i in range(len(decay))]
            self.gamma = [decay[i][1] for i in range(len(decay))]
        self.decay_opt = [np.array(x, dtype=np.complex128) for x in decay_opt]

        if W == []:
            W = np.eye(len(self.Hamiltonian_derivative))
        self.W = W

        self.accuracy = accuracy
        self.seed = seed

        if self.mtype == 'projection':
            if measurement0 == []: 
                np.random.seed(self.seed)
                M = [[] for i in range(len(self.rho0))]
                for i in range(len(self.rho0)):
                    r_ini = 2*np.random.random(len(self.rho0))-np.ones(len(self.rho0))
                    r = r_ini/np.linalg.norm(r_ini)
                    phi = 2*np.pi*np.random.random(len(self.rho0))
                    M[i] = [r[i]*np.exp(1.0j*phi[i]) for i in range(len(self.rho0))]
                self.Measurement = gramschmidt(np.array(M))
            elif len(measurement0) >= 1:
                self.Measurement = [measurement0[0][i] for i in range(len(self.rho0))]

        elif self.mtype == 'sicpovm':
            file_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'sic_fiducial_vectors/d%d.txt'%(len(self.rho0)))
            data = np.loadtxt(file_path)
            fiducial = data[:,0] + data[:,1]*1.0j
            fiducial = np.array(fiducial).reshape(len(fiducial),1) 
            self.povm_basis = sic_povm(fiducial)
            self.M_num = mgiven[1]
        
        elif self.mtype == 'given':
            if type(mgiven[0]) != list:
                raise TypeError('The given POVMs should be a list!') 
            else:
                for i in range(len(mgiven[0])):
                    val, vec = np.linalg.eig(mgiven[0])
                    if np.all(val.round(8) >= 0):
                        pass
                    else:
                        raise TypeError('The given POVMs should be semidefinite!') 
                M = np.zeros((len(self.rho0), len(self.rho0)), dtype=np.complex128)
                for i in range(len(mgiven[0])):
                    M += mgiven[0][i]
                if np.all(M.round(8)-np.identity(len(self.rho0)) == 0):
                    pass
                else:
                    raise TypeError('The sum of the given POVMs should be identity matrix!') 

            self.povm_basis = mgiven[0]
            self.M_num = mgiven[1]
        else:
            raise ValueError("{!r} is not a valid value for mtype, supported values are 'projection', 'sicpovm', 'given'.".format(self.mtype))

    def load_save(self):
        file_load = open('measurements.csv', 'r')
        file_load = ''.join([i for i in file_load]).replace("im", "j")
        file_load = ''.join([i for i in file_load]).replace(" ", "")
        file_save = open("measurements.csv","w")
        file_save.writelines(file_load)
        file_save.close()

def MeasurementOpt(*args, mtype='projection', mgiven=[], method='AD', **kwargs):

    if method == 'AD':
        return Measure.AD_Mopt(mtype, mgiven, *args, **kwargs)
    elif method == 'PSO':
        return Measure.PSO_Mopt(mtype, mgiven, *args, **kwargs)
    elif method == 'DE':
        return Measure.DE_Mopt(mtype, mgiven, *args, **kwargs)
    else:
        raise ValueError("{!r} is not a valid value for method, supported values are 'AD', 'PSO', 'DE'.".format(method))