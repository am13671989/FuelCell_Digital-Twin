# Run with:  python plot_anode.py     (needs: pandas matplotlib)
import pandas as pd, matplotlib.pyplot as plt

def seg(d, name, n=5): return pd.concat([d["s.%s[%d]" % (name, k)] for k in range(1, n + 1)], axis=1)

# ---- Test 1: load step ----
d = pd.read_csv("FullLoadStepTest_res.csv"); t = d["time"]
fig, ax = plt.subplots(2, 2, sharex=True, figsize=(11, 7))
ax[0, 0].plot(t, d["s.p_an_mean"] / 1e5, label="anode"); ax[0, 0].plot(t, d["s.p_mean"] / 1e5, label="cathode")
ax[0, 0].set_ylabel("mean pressure (bar abs)"); ax[0, 0].legend(fontsize=8)
ax[0, 1].plot(t, d["s.W_inj"] * 1000, label="injector (fresh H2)"); ax[0, 1].plot(t, d["s.W_ej"] * 1000, label="ejector")
ax[0, 1].plot(t, d["s.W_pump"] * 1000, label="recirculation pump"); ax[0, 1].set_ylabel("flow (g/s)"); ax[0, 1].legend(fontsize=8)
ax[1, 0].plot(t, d["s.x_N2_out"], label="N2 fraction, outlet"); ax[1, 0].plot(t, d["s.x_N2_in"], label="N2 fraction, inlet")
ax[1, 0].plot(t, 0.05 * d["s.purge"].astype(float), "k", lw=0.8, label="purge open (scaled)"); ax[1, 0].legend(fontsize=8)
ax[1, 0].set_ylabel("anode N2 mole fraction")
ax[1, 1].plot(t, d["s.V_stack"], label="stack voltage (V)"); ax2 = ax[1, 1].twinx()
ax2.plot(t, d["s.eta_net"] * 100, "g", label="net efficiency (%)"); ax2.set_ylim(0, 70); ax2.set_ylabel("net efficiency, LHV (%)")
ax[1, 1].set_ylabel("stack voltage (V)")
for a in ax.flat: a.grid(True)
ax[1, 0].set_xlabel("time (s)"); ax[1, 1].set_xlabel("time (s)"); fig.suptitle("Anode loop: load step 100 A -> 350 A at 100 s")
purge = d["s.purge"].astype(float); n_purges = int(((purge.diff() > 0)).sum())
print("Load step test: %d purge events; max |anode - cathode| pressure = %.3f bar; net efficiency at end = %.1f %%" % (
    n_purges, d["s.dP_mem"].abs().max() / 1e5, 100 * d["s.eta_net"].iloc[-1]))

# ---- Test 2: hydrogen starvation ----
d = pd.read_csv("FullAnodeStarvationTest_res.csv"); t = d["time"]
fig, ax = plt.subplots(2, 2, sharex=True, figsize=(11, 7))
for k, y in enumerate(seg(d, "p_ha").T.values, 1): ax[0, 0].plot(t, y, label="segment %d" % k)
ax[0, 0].set_ylabel("anode H2 partial pressure (atm)"); ax[0, 0].legend(fontsize=8)
ax[0, 1].plot(t, d["s.x_N2_out"], label="N2 fraction, outlet"); ax[0, 1].plot(t, 0.1 * d["s.purge"].astype(float), "k", lw=0.8, label="purge open (scaled)")
ax[0, 1].axvline(40, color="r", ls=":"); ax[0, 1].legend(fontsize=8); ax[0, 1].set_ylabel("anode N2 mole fraction")
for k, y in enumerate(seg(d, "V_loc").T.values, 1): ax[1, 0].plot(t, y, label="segment %d" % k)
ax[1, 0].axhline(0, color="r", ls=":"); ax[1, 0].set_ylabel("local cell voltage (V)"); ax[1, 0].legend(fontsize=8)
ax[1, 1].plot(t, d["s.V_cell"], label="mean cell voltage"); ax[1, 1].plot(t, seg(d, "V_loc").min(axis=1), "--", label="worst segment")
ax[1, 1].axhline(0, color="r", ls=":"); ax[1, 1].legend(fontsize=8); ax[1, 1].set_ylabel("cell voltage (V)")
for a in ax.flat: a.grid(True)
ax[1, 0].set_xlabel("time (s)"); ax[1, 1].set_xlabel("time (s)"); fig.suptitle("Anode starvation: purge disabled at 40 s, 5x crossover, 200 A")
print("Starvation test: final outlet N2 fraction = %.2f; worst segment voltage = %.3f V; mean cell voltage drop since t = 40 s: %.3f V" % (
    d["s.x_N2_out"].iloc[-1], seg(d, "V_loc").min().min(), d["s.V_cell"][t.sub(40).abs().idxmin()] - d["s.V_cell"].iloc[-1]))
plt.show()
