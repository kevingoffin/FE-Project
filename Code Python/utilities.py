import numpy as np
from scipy.optimize import minimize
from scipy.special import erfi
import warnings

def erfid(x, y):
    """Calculates difference between imaginary error functions (erfi(x/√2) - erfi(y/√2))"""
    return erfi(x/np.sqrt(2)) - erfi(y/np.sqrt(2))

def mu(d, u, c, f, sigma, theta, l):
    """Computes strategy return given bands d (lower) and u (upper)"""
    term1 = np.log(1 + f*(np.exp(sigma*(u - d - c)) - 1)) / erfid(u, d)
    term2 = np.log(1 + f*(np.exp(sigma*(l - d - c)) - 1)) / erfid(d, l)
    return (2/(theta*np.pi)) * (term1 + term2)

def maximize_mu(c_vals, l, sigma, theta, f):
    """Main optimization function (sequential version)"""
    n = len(c_vals)
    d_vals = np.zeros(n)
    u_vals = np.zeros(n)
    
    # Initial guess [d, u]
    x0 = np.array([-0.5, 0.5])
    
    for i, c in enumerate(c_vals):
        # Bounds for current cost value
        bounds = [(l + 0.01, 0.6), (l + c, 3)]
        
        # Constraints for current cost
        constraints = [
            {'type': 'ineq', 'fun': lambda x: x[1] - x[0] - c},  # u-d > c
            {'type': 'ineq', 'fun': lambda x: x[0] - l},         # d > l
            {'type': 'ineq', 'fun': lambda x: x[1] - x[0]}       # u > d
        ]
        
        try:
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                
                res = minimize(
                    fun=lambda x: -mu(x[0], x[1], c, f, sigma, theta, l),
                    x0=x0,
                    bounds=bounds,
                    constraints=constraints,
                    method='SLSQP',
                    options={'maxiter': 500, 'ftol': 1e-8}
                )
                
                if res.success:
                    d_vals[i], u_vals[i] = res.x
                else:
                    d_vals[i], u_vals[i] = np.nan, np.nan
                    
        except:
            d_vals[i], u_vals[i] = np.nan, np.nan
    
    return d_vals, u_vals