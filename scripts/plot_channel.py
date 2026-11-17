# Run with:  python plot_channel.py     (needs: pandas matplotlib)
import pandas as pd, matplotlib.pyplot as plt

def seg(d, name, n=5):
    return [d["s.%s[%d]" % (name, k)] for k in range(1, n + 1)]

for prefix, title in [("ChannelLoadStepTest", "Load step 100 A -> 350 A at t = 100 s"),
                      ("ChannelStarvationTest", "Starvation: OER setpoint 2.0 -> 0.8 at t = 80 s, 200 A")]:
    d = pd.read_csv(prefix + "_res.csv"); t = d["time"]
    fig, ax = plt.subplots(2, 2, sharex=True, figsize=(11, 7))
    for k, y in enumerate(seg(d, "p_a"), 1): ax[0, 0].plot(t, y, label="segment %d%s" % (k, " (inlet)" if k == 1 else " (outlet)" if k == 5 else ""))
    ax[0, 0].set_ylabel("O2 partial pressure (atm)"); ax[0, 0].legend(fontsize=8)
    for k, y in enumerate(seg(d, "i_loc"), 1): ax[0, 1].plot(t, y, label="segment %d" % k)
    ax[0, 1].set_ylabel("local current density (A/cm2)")
    ax[1, 0].plot(t, d["s.OER"], label="OER"); ax[1, 0].axhline(1, color="r", ls=":", label="OER = 1")
    ax[1, 0].set_ylabel("oxygen excess ratio"); ax[1, 0].legend(fontsize=8)
    ax[1, 1].plot(t, d["s.V_cell"], label="mean cell voltage")
    ax[1, 1].plot(t, pd.concat(seg(d, "V_loc"), axis=1).min(axis=1), "--", label="worst segment")
    ax[1, 1].axhline(0, color="r", ls=":"); ax[1, 1].set_ylabel("cell voltage (V)"); ax[1, 1].legend(fontsize=8)
    for a in ax.flat: a.grid(True)
    ax[1, 0].set_xlabel("time (s)"); ax[1, 1].set_xlabel("time (s)"); fig.suptitle(title); fig.tight_layout()
    print(prefix, ": min OER = %.2f, min mean cell voltage = %.3f V, min segment voltage = %.3f V" % (
        d["s.OER"][t > 5].min(), d["s.V_cell"][t > 5].min(), pd.concat(seg(d, "V_loc"), axis=1)[t > 5].min().min()))
plt.show()
