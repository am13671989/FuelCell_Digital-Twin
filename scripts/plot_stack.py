# Run with:  python plot.py   (needs: pip install pandas matplotlib)
import pandas as pd, matplotlib.pyplot as plt

d = pd.read_csv("StackDynamicTest_res.csv")
fig, ax = plt.subplots(3, 1, sharex=True, figsize=(8, 8))
for a, col, lab in zip(ax, ["s.V", "s.T", "s.lambda"], ["Stack voltage (V)", "Stack temperature (K)", "Membrane lambda"]):
    a.plot(d["time"], d[col]); a.set_ylabel(lab); a.grid(True)
ax[-1].set_xlabel("time (s)")
fig.suptitle("StackDynamicTest")

p = pd.read_csv("StackVoltageTest_res.csv")
plt.figure(figsize=(6, 4))
plt.plot(p["s.I"], p["s.V"]); plt.xlabel("Current (A)"); plt.ylabel("Stack voltage (V)")
plt.title("Polarization curve (StackVoltageTest)"); plt.grid(True)
plt.show()
