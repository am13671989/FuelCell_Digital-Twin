within FCDT.Tests;
model CoolingIonTest "8 h at 50 kW heat: contaminated loop (4 uS/cm, fast ion release), small resin bed, filter valve enabled"
  parameter Real filt = 1 "1 = filter valve enabled";
  FCDT.Cooling.CoolingLoop c(kappa_start = 4.0, r0 = 1.0, Cap = 400);
  parameter Real Cth = 60000;
  parameter Real hA = 5400;
  Real T(start = 303.15, fixed = true);
equation
  Cth*der(T) = 50000 - c.Q_st;
  c.Q_st = hA*(T - c.T_cs);
  c.V_stack = 200;
  c.filter_enable = filt;
end CoolingIonTest;
