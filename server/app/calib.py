"""Stage A calibration: least squares, then MCMC (emcee) for 90% intervals. Mirrors the Modelica voltage model."""
import numpy as np, emcee
from scipy.optimize import least_squares

R, F = 8.314, 96485.0
NAMES = ["log10_i0", "alpha", "r_ohm", "ilim", "c"]
X0 = np.array([-4.0, 0.5, 0.15, 1.6, 0.08])
LO = np.array([-8.0, 0.2, 0.02, 0.8, 0.0])
HI = np.array([-2.0, 1.0, 0.60, 3.0, 0.40])

def cell_v(i, th, T=353.15, pH2=1.5, pO2=0.3, iloss=2e-3):
    i = np.asarray(i, float)
    E = 1.229 - 0.85e-3 * (T - 298.15) + R * T / (2 * F) * np.log(pH2 * np.sqrt(pO2))
    return (E - R * T / (th[1] * F) * np.log((i + iloss) / 10 ** th[0]) - i * th[2]
            + th[4] * np.log(np.clip(1 - i / th[3], 1e-6, None)))

def calibrate(i, v, n_steps=1500, **cond):
    i, v = np.asarray(i, float), np.asarray(v, float)
    res = lambda th: cell_v(i, th, **cond) - v
    fit = least_squares(res, X0, bounds=(LO, HI), x_scale=(1, .5, .1, 1, .1))
    sigma = max(float(np.std(fit.fun)), 1e-4)
    logp = lambda th: -np.inf if (np.any(th < LO) or np.any(th > HI)) else -0.5 * np.sum((res(th) / sigma) ** 2)
    p0 = np.clip(fit.x + 1e-3 * np.random.randn(24, 5) * (HI - LO), LO + 1e-9, HI - 1e-9)
    s = emcee.EnsembleSampler(24, 5, logp); s.run_mcmc(p0, n_steps, progress=False)
    ch = s.get_chain(discard=n_steps // 2, flat=True)
    g = np.linspace(0.01, 0.97 * fit.x[3], 60)
    cv = np.array([cell_v(g, t, **cond) for t in ch[np.random.choice(len(ch), 200)]])
    return {"params": dict(zip(NAMES, fit.x.tolist())),
            "ci90": {n: np.percentile(ch[:, k], [5, 95]).tolist() for k, n in enumerate(NAMES)},
            "rmse_V": float(np.sqrt(np.mean(fit.fun ** 2))),
            "curve": {"i": g.tolist(), "v": cell_v(g, fit.x, **cond).tolist(),
                      "lo": np.percentile(cv, 5, 0).tolist(), "hi": np.percentile(cv, 95, 0).tolist()}}
