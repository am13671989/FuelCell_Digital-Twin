within FCDT.Stack;
model StackDynamic
  parameter Integer N = 300 "cells";
  parameter Real A = 0.03 "active area, m2";
  parameter Real alpha = 0.5, i0 = 1e-4, iloss = 2e-3 "A/cm2";
  parameter Real ilim = 1.8 "A/cm2", c = 0.1 "V";
  parameter Real tm = 25e-4 "cm", Rc = 0.03 "ohm cm2";
  parameter Real Cth = 60000 "stack thermal mass, J/K";
  parameter Real hA = 5400 "stack-coolant conductance, W/K";
  parameter Real tau_lambda = 5 "hydration time constant, s";
  parameter Real kw = 0.3 "water activity gain from product water, per A/cm2";
  input Real I "A", pH2 "atm", pO2 "atm", Tcool "K", a_in "inlet water activity";
  output Real V "stack voltage, V";
  Real T(start = 303.15, fixed = true) "stack temperature, K";
  Real lambda(start = 6, fixed = true) "membrane water content";
protected
  constant Real R = 8.314, F = 96485;
  Real i, E, a, lambda_eq, sigma, Vcell;
equation
  i = I/(A*1e4);
  E = 1.229 - 0.85e-3*(T - 298.15) + R*T/(2*F)*log(pH2*sqrt(pO2));
  a = min(1.0, a_in + kw*i);
  lambda_eq = 0.043 + 17.81*a - 39.85*a^2 + 36.0*a^3;
  der(lambda) = (lambda_eq - lambda)/tau_lambda;
  sigma = (0.005139*lambda - 0.00326)*exp(1268*(1/303.15 - 1/T));
  Vcell = E - R*T/(alpha*F)*log((i + iloss)/i0) - i*(tm/sigma + Rc) + c*log(1 - i/ilim);
  V = N*Vcell;
  Cth*der(T) = N*I*(1.254 - Vcell) - hA*(T - Tcool);
end StackDynamic;
