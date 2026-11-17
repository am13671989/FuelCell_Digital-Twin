within FCDT.Air;
model AirPathChannelSystem "Stack with n-segment cathode channel (O2 depletion along the channel, starvation) plus air path"
  parameter Integer n = 5 "number of cathode channel segments";
  // ---- ambient and constants ----
  parameter Real p_amb = 101325 "Pa";
  parameter Real T_amb = 298.15 "K";
  constant Real R = 8.314;
  constant Real F = 96485;
  constant Real R_O2 = 259.8 "J/kg/K";
  constant Real R_N2 = 296.8 "J/kg/K";
  constant Real R_air = 287.0 "J/kg/K";
  constant Real M_O2 = 0.032 "kg/mol";
  // ---- stack ----
  parameter Integer N = 300 "cells";
  parameter Real A = 0.03 "active area, m2";
  parameter Real alpha = 0.5;
  parameter Real i0 = 1e-4 "A/cm2 at p_ref";
  parameter Real iloss = 2e-3 "A/cm2";
  parameter Real ilim = 2.4 "limiting current density at p_ref, A/cm2";
  parameter Real c = 0.1 "V";
  parameter Real tm = 25e-4 "cm";
  parameter Real Rc = 0.03 "ohm cm2";
  parameter Real Cth = 60000 "J/K";
  parameter Real hA = 5400 "W/K";
  parameter Real tau_lambda = 5 "s";
  parameter Real kw = 0.3;
  parameter Real pH2 = 1.5 "atm (fixed until the hydrogen loop is modeled)";
  parameter Real Tcool = 333.15 "K";
  parameter Real a_in = 0.6;
  // ---- channel and starvation model ----
  parameter Real p_ref = 0.3 "reference O2 partial pressure for i0 and ilim, atm";
  parameter Real gam = 1.5 "current distribution exponent (local current ~ pO2^gam)";
  parameter Real eps = 0.02 "smoothing of the concentration-loss log";
  parameter Real p_lim = 5e-4 "O2 availability limiter, atm";
  parameter Real V_ca = 0.02 "total cathode channel volume, m3";
  parameter Real k_chan = 1.0e-5 "overall channel flow constant, kg/s/Pa";
  parameter Real Vseg = V_ca/n;
  parameter Real k_seg = n*k_chan;
  // ---- compressor, manifold, valve, controllers (as in AirPathSystem) ----
  parameter Real w_n = 10472 "rad/s";
  parameter Real W_n = 0.10 "kg/s";
  parameter Real pr_gain = 3.0;
  parameter Real eta_c = 0.70;
  parameter Real eta_m = 0.90;
  parameter Real tau_cp = 0.15 "s";
  parameter Real cp_air = 1005;
  parameter Real V_sm = 0.02 "m3";
  parameter Real T_sm = 330 "K";
  parameter Real k_sm = 2.5e-6 "kg/s/Pa";
  parameter Real k_bp = 2.0e-6 "kg/s/Pa";
  parameter Real Kpw = 1.0, Kiw = 3.0, Kpb = 1.0, Kib = 3.0, Kaw = 5.0;

  input Real I_load(start = 100) "stack current, A";
  input Real OER_ref(start = 2.0) "oxygen excess ratio setpoint";

  Real T(start = 303.15, fixed = true) "stack and cathode gas temperature, K";
  Real lam(start = 6, fixed = true) "membrane water content";
  Real w(start = 0.25*w_n, fixed = true) "compressor speed, rad/s";
  Real p_sm(start = p_amb, fixed = true) "supply manifold pressure, Pa";
  Real z_w(start = 0.1, fixed = true);
  Real z_p(start = 0.2, fixed = true);
  Real m_O2[n](each start = 0.21*p_amb*Vseg/(R_O2*303.15), each fixed = true) "O2 mass per segment, kg";
  Real m_N2[n](each start = 0.79*p_amb*Vseg/(R_N2*303.15), each fixed = true) "N2 mass per segment, kg";

  // channel variables (segment 1 = inlet, segment n = outlet)
  Real p_O2[n], p_N2[n], p[n], y_O2[n], p_a[n], pe[n], wr[n], wk[n];
  Real i_loc[n] "local current density, A/cm2";
  Real E[n], s[n], V_loc[n] "local cell voltage, V";
  Real W_up[n], W_dn[n], Fin_O2[n], Fin_N2[n], Fout_O2[n], Fout_N2[n], Wr[n];
  Real wsum, i_avg, a, lam_eq, sigma, V_cell, V_stack;
  // air path
  Real r, pr, x_s, W_cp, W_O2_rct, W_ref, e_w, r_raw, r_sat;
  Real p_mean, p_set, e_p, u_raw, u;
  Real P_stack, P_cp, P_net, W_H2, eta_net, OER;
equation
  // ---- cathode channel segments ----
  for k in 1:n loop
    p_O2[k] = m_O2[k]*R_O2*T/Vseg;
    p_N2[k] = m_N2[k]*R_N2*T/Vseg;
    p[k] = p_O2[k] + p_N2[k];
    y_O2[k] = m_O2[k]/(m_O2[k] + m_N2[k]);
    p_a[k] = p_O2[k]/p_amb;
    pe[k] = sqrt(p_a[k]^2 + 1e-4);
    wr[k] = pe[k]^gam;
    wk[k] = wr[k]/(wsum/n);
    i_loc[k] = i_avg*wk[k];
    E[k] = 1.229 - 0.85e-3*(T - 298.15) + R*T/(2*F)*log(pH2*sqrt(pe[k]));
    s[k] = 1 - i_loc[k]*p_ref/(ilim*pe[k]);
    V_loc[k] = E[k] - R*T/(alpha*F)*log((i_loc[k] + iloss)/(i0*pe[k]/p_ref))
               - i_loc[k]*(tm/sigma + Rc) + c*log(0.5*(s[k] + sqrt(s[k]^2 + 4*eps^2)));
    Fout_O2[k] = y_O2[k]*W_dn[k];
    Fout_N2[k] = (1 - y_O2[k])*W_dn[k];
    Wr[k] = N*M_O2/(4*F)*I_load*wk[k]/n*tanh(p_a[k]/p_lim);
    der(m_O2[k]) = Fin_O2[k] - Fout_O2[k] - Wr[k];
    der(m_N2[k]) = Fin_N2[k] - Fout_N2[k];
  end for;
  wsum = sum(wr);
  W_up[1] = k_sm*(p_sm - p[1]);
  for k in 2:n loop
    W_up[k] = W_dn[k - 1];
  end for;
  for k in 1:n - 1 loop
    W_dn[k] = k_seg*(p[k] - p[k + 1]);
  end for;
  W_dn[n] = u*k_bp*(p[n] - p_amb);
  Fin_O2[1] = 0.233*W_up[1];
  Fin_N2[1] = 0.767*W_up[1];
  for k in 2:n loop
    Fin_O2[k] = Fout_O2[k - 1];
    Fin_N2[k] = Fout_N2[k - 1];
  end for;
  // ---- stack: voltage, thermal, hydration ----
  i_avg = I_load/(A*1e4);
  V_cell = sum(V_loc)/n;
  V_stack = N*V_cell;
  a = min(1.0, a_in + kw*i_avg);
  lam_eq = 0.043 + 17.81*a - 39.85*a^2 + 36.0*a^3;
  der(lam) = (lam_eq - lam)/tau_lambda;
  sigma = (0.005139*lam - 0.00326)*exp(1268*(1/303.15 - 1/T));
  Cth*der(T) = N*I_load*(1.254 - V_cell) - hA*(T - Tcool);
  // ---- compressor, manifold ----
  r = w/w_n;
  pr = p_sm/p_amb;
  x_s = (pr - 1)/(pr_gain*r^2);
  W_cp = W_n*r*(1 - x_s^2);
  der(p_sm) = R_air*T_sm/V_sm*(W_cp - W_up[1]);
  // ---- OER controller ----
  W_O2_rct = N*I_load/(4*F)*M_O2;
  W_ref = OER_ref*W_O2_rct/0.233;
  e_w = W_ref - W_cp;
  r_raw = Kpw*e_w/W_n + Kiw*z_w;
  r_sat = min(1.05, max(0.15, r_raw));
  der(z_w) = e_w/W_n + Kaw*(r_sat - r_raw);
  der(w) = (r_sat*w_n - w)/tau_cp;
  // ---- pressure controller and valve ----
  p_mean = sum(p)/n;
  p_set = p_amb*(1.15 + 0.45*min(1, I_load/400));
  e_p = (p_mean - p_set)/1e5;
  u_raw = Kpb*e_p + Kib*z_p;
  u = min(1.0, max(0.05, u_raw));
  der(z_p) = e_p + Kaw*(u - u_raw);
  // ---- power and efficiency (LHV) ----
  P_stack = V_stack*I_load;
  P_cp = W_cp*cp_air*T_amb/eta_c*(pr^0.2857 - 1)/eta_m;
  P_net = P_stack - P_cp;
  W_H2 = N*I_load/(2*F)*0.002016;
  eta_net = P_net/(W_H2*120e6);
  OER = 0.233*W_up[1]/(W_O2_rct + 1e-9);
end AirPathChannelSystem;
