within FCDT.Stack;
model StackVoltage
  parameter Integer N = 300 "cells";
  parameter Real A = 0.03 "active area, m2";
  parameter Real alpha = 0.5, i0 = 1e-4, iloss = 2e-3 "A/cm2";
  parameter Real ilim = 1.8 "A/cm2", c = 0.1 "V";
  parameter Real tm = 25e-4 "membrane thickness, cm", Rc = 0.03 "ohm cm2";
  input Real T "K", pH2 "atm", pO2 "atm", lambda, I "A";
  output Real V;
protected
  constant Real R = 8.314, F = 96485;
  Real i = I/(A*1e4) "A/cm2";
  Real E, eta_act, eta_ohm, eta_conc, sigma;
equation
  E = 1.229 - 0.85e-3*(T-298.15) + R*T/(2*F)*log(pH2*sqrt(pO2));
  eta_act = R*T/(alpha*F)*log((i+iloss)/i0);
  sigma = (0.005139*lambda - 0.00326)*exp(1268*(1/303.15 - 1/T));
  eta_ohm = i*(tm/sigma + Rc);
  eta_conc = -c*log(1 - i/ilim);
  V = N*(E - eta_act - eta_ohm - eta_conc);
end StackVoltage;
