# Run with:  python plot_cooling.py     (needs: pandas matplotlib)
import pandas as pd, matplotlib.pyplot as plt

# ---- 1. Warm-up and load step (stack as a thermal mass) ----
d = pd.read_csv("CoolingWarmupTest_res.csv"); t = d["time"]
fig, ax = plt.subplots(2, 2, sharex=True, figsize=(11, 7))
ax[0, 0].plot(t, d["T"] - 273.15, label="stack"); ax[0, 0].plot(t, d["c.T_cs"] - 273.15, label="coolant out of stack")
ax[0, 0].plot(t, d["c.T_rad"] - 273.15, label="radiator"); ax[0, 0].axhline(60, color="k", ls=":", label="setpoint")
ax[0, 0].set_ylabel("temperature (C)"); ax[0, 0].legend(fontsize=8)
ax[0, 1].plot(t, d["c.u_v"] * 100, label="bypass valve to radiator (%)"); ax[0, 1].plot(t, d["c.s_f"] * 100, label="fan speed (%)")
ax[0, 1].set_ylabel("%"); ax[0, 1].legend(fontsize=8)
ax[1, 0].plot(t, d["c.m_c"], label="coolant flow (kg/s)"); ax2 = ax[1, 0].twinx(); ax2.plot(t, d["c.Q_rad"] / 1e3, "g", label="radiator heat (kW)")
ax[1, 0].set_ylabel("coolant flow (kg/s)"); ax2.set_ylabel("radiator heat (kW)")
ax[1, 1].plot(t, d["c.P_pump"], label="pump"); ax[1, 1].plot(t, d["c.P_fan"], label="fan"); ax[1, 1].set_ylabel("power (W)"); ax[1, 1].legend(fontsize=8)
for a in ax.flat: a.grid(True)
ax[1, 0].set_xlabel("time (s)"); ax[1, 1].set_xlabel("time (s)"); fig.suptitle("Cooling loop: cold start, then heat step 18.5 kW -> 85 kW at 100 s")
open_t = t[d["c.u_v"] > 0.05].iloc[0]
print("Warm-up: radiator valve first opens at %.0f s; max stack temperature %.1f C; final fan speed %.0f %%; pump + fan power at end %.2f kW" % (
    open_t, d["T"].max() - 273.15, 100 * d["c.s_f"].iloc[-1], (d["c.P_pump"].iloc[-1] + d["c.P_fan"].iloc[-1]) / 1e3))

# ---- 2. Ion filter ----
on = pd.read_csv("CoolingIonTest_res.csv"); off = pd.read_csv("CoolingIonNoFilterTest_res.csv"); h = on["time"] / 3600
fig, ax = plt.subplots(2, 2, sharex=True, figsize=(11, 7))
ax[0, 0].plot(h, on["c.kappa"], label="filter valve enabled"); ax[0, 0].plot(off["time"] / 3600, off["c.kappa"], label="filter valve closed")
ax[0, 0].set_ylabel("coolant conductivity (uS/cm)"); ax[0, 0].legend(fontsize=8)
ax[0, 1].plot(h, on["c.u_f"] * 100, label="filter valve opening (%)"); ax[0, 1].plot(h, on["c.phi"] * 100, label="resin saturation (%)")
ax[0, 1].legend(fontsize=8); ax[0, 1].set_ylabel("%")
ax[1, 0].plot(h, on["c.R_iso"], label="filter enabled"); ax[1, 0].plot(off["time"] / 3600, off["c.R_iso"], label="filter closed")
ax[1, 0].axhline(on["c.R_req"].iloc[0], color="r", ls=":", label="required (500 ohm/V)"); ax[1, 0].set_ylabel("isolation resistance (kOhm)"); ax[1, 0].legend(fontsize=8)
ax[1, 1].plot(h, on["c.iso_margin"], label="filter enabled"); ax[1, 1].plot(off["time"] / 3600, off["c.iso_margin"], label="filter closed")
ax[1, 1].axhline(1, color="r", ls=":"); ax[1, 1].set_ylabel("isolation margin (-)"); ax[1, 1].legend(fontsize=8)
for a in ax.flat: a.grid(True)
ax[1, 0].set_xlabel("time (h)"); ax[1, 1].set_xlabel("time (h)"); fig.suptitle("Ion filter: contaminated loop, 8 h")
bad = off.loc[off["c.iso_margin"] < 1, "time"]
print("Ion filter: with filter, conductivity min %.2f and final %.2f uS/cm, resin saturation at end %.0f %%; without filter, conductivity at end %.1f uS/cm, isolation margin below 1 from %s" % (
    on["c.kappa"].min(), on["c.kappa"].iloc[-1], 100 * on["c.phi"].iloc[-1], off["c.kappa"].iloc[-1],
    ("%.1f h" % (bad.iloc[0] / 3600)) if len(bad) else "never"))

# ---- 3. Full system with cooling loop ----
d = pd.read_csv("FullCoolLoadStepTest_res.csv"); t = d["time"]
fig, ax = plt.subplots(2, 2, sharex=True, figsize=(11, 7))
ax[0, 0].plot(t, d["s.T"] - 273.15, label="stack"); ax[0, 0].plot(t, d["s.Tcool"] - 273.15, label="coolant out"); ax[0, 0].set_ylabel("temperature (C)"); ax[0, 0].legend(fontsize=8)
ax[0, 1].plot(t, d["s.cool.u_v"] * 100, label="bypass valve to radiator (%)"); ax[0, 1].plot(t, d["s.cool.s_f"] * 100, label="fan speed (%)"); ax[0, 1].legend(fontsize=8)
ax[1, 0].plot(t, d["s.V_stack"], label="stack voltage (V)"); ax[1, 0].set_ylabel("stack voltage (V)")
ax[1, 1].plot(t, d["s.eta_net"] * 100, label="net efficiency (%)"); ax2 = ax[1, 1].twinx(); ax2.plot(t, d["s.cool.P_cool"] / 1e3, "g", label="cooling power (kW)")
ax[1, 1].set_ylabel("net efficiency, LHV (%)"); ax2.set_ylabel("pump + fan power (kW)")
for a in ax.flat: a.grid(True)
ax[1, 0].set_xlabel("time (s)"); ax[1, 1].set_xlabel("time (s)"); fig.suptitle("Full system with cooling loop: cold start, 100 A -> 350 A at 100 s")
print("Full system: max stack temperature %.1f C; net efficiency at end %.1f %%; cooling power at end %.2f kW" % (
    d["s.T"].max() - 273.15, 100 * d["s.eta_net"].iloc[-1], d["s.cool.P_cool"].iloc[-1] / 1e3))
plt.show()
