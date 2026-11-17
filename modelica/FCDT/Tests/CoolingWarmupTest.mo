within FCDT.Tests;
model CoolingWarmupTest "Cold start at 18.5 kW heat, then 85 kW from t = 100 s; stack as a thermal mass"
  FCDT.Cooling.CoolingLoop c;
  parameter Real Cth = 60000 "stack thermal mass, J/K";
  parameter Real hA = 5400 "stack to coolant conductance, W/K";
  Real T(start = 303.15, fixed = true) "stack temperature, K";
  Real Q_gen "heat generated in the stack, W";
equation
  Q_gen = if time < 100 then 18500 else 85000;
  Cth*der(T) = Q_gen - c.Q_st;
  c.Q_st = hA*(T - c.T_cs);
  c.V_stack = 200;
  c.filter_enable = 1;
end CoolingWarmupTest;
