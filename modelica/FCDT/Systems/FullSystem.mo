within FCDT.Systems;
model FullSystem "Stack + cathode air path with channel + anode loop (injector, ejector, recirculation pump, N2 crossover, purge)"
  parameter Integer n = 5 "number of channel segments (cathode and anode, co-flow)";
  // ---- ambient and constants ----
  parameter Real p_amb = 101325 "Pa";
  parameter Real T_amb = 298.15 "K";
  constant Real R = 8.314;
  constant Real F = 96485;
  constant Real R_O2 = 259.8 "J/kg/K";
  constant Real R_N2 = 296.8 "J/kg/K";
  constant Real R_H2 = 4124 "J/kg/K";
  constant Real R_air = 287.0 "J/kg/K";
  constant Real M_O2 = 0.032 "kg/mol";
  constant Real M_H2 = 0.002016 "kg/mol";
  // ---- stack ----
  parameter Integer N = 300 "cells";
  parameter Real A = 0.03 "active area, m2";
  parameter Real alpha = 0.5;
  parameter Real i0 = 1e-4 "A/cm2 at p_ref";
  parameter Real iloss = 2e-3 "A/cm2";
  parameter Real ilim = 2.4 "cathode limiting current density at p_ref, A/cm2";
  parameter Real c = 0.1 "V";
  parameter Real tm = 25e-4 "cm";
  parameter Real Rc = 0.03 "ohm cm2";
  parameter Real Cth = 60000 "J/K";
  parameter Real hA = 5400 "W/K";
  parameter Real tau_lambda = 5 "s";
  parameter Real kw = 0.3;
  parameter Real Tcool = 333.15 "K";
  parameter Real a_in = 0.6;
  // ---- cathode channel and starvation ----
  parameter Real p_ref = 0.3 "reference O2 partial pressure, atm";
  parameter Real gam = 1.5 "current distribution exponent for O2";
  parameter Real eps = 0.02;
  parameter Real p_lim = 5e-4 "reactant availability limiter, atm";
  parameter Real V_ca = 0.02 "m3";
  parameter Real k_chan = 1.0e-5 "kg/s/Pa";
  parameter Real Vseg = V_ca/n;
  parameter Real k_seg = n*k_chan;
  // ---- compressor, manifold, valve, controllers ----
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
  // ---- anode loop ----
  parameter Real V_an = 0.015 "total anode channel volume, m3";
  parameter Real k_chan_a = 4e-7 "overall anode channel flow constant, kg/s/Pa";
  parameter Real Vsa = V_an/n;
  parameter Real k_seg_a = n*k_chan_a;
  parameter Real p_tank = 8e5 "regulated H2 supply pressure, Pa";
  parameter Real k_inj = 5e-9 "injector flow constant at full opening, kg/s/Pa";
  parameter Real ER_n = 1.2 "ejector entrainment ratio at high primary flow";
  parameter Real W_half = 3e-4 "primary flow at half entrainment, kg/s";
  parameter Real SR_ref = 1.8 "anode recirculation stoichiometry target";
  parameter Real tau_pump = 0.5 "s";
  parameter Real dp_pump = 15000 "pump pressure rise, Pa";
  parameter Real eta_pump = 0.5;
  parameter Real k_cross = 3e-10 "N2 crossover constant (whole stack), kg/s/Pa";
  parameter Real k_purge = 2e-8 "purge valve flow constant, kg/s/Pa";
  parameter Real x_hi = 0.15 "purge opens above this outlet N2 mole fraction";
  parameter Real x_lo = 0.08 "purge closes below this outlet N2 mole fraction";
  parameter Real dp_an = 5000 "anode pressure above cathode, Pa";
  parameter Real Kpa = 2.0, Kia = 5.0;
  parameter Real gam_h = 1.0 "current distribution exponent for H2";
  parameter Real p_href = 1.5 "reference H2 partial pressure, atm";
  parameter Real ilim_a = 8.0 "anode limiting current density at p_href, A/cm2";
  parameter Real c_a = 0.05 "V";

  input Real I_load(start = 100) "stack current, A";
  input Real OER_ref(start = 2.0) "oxygen excess ratio setpoint";
  input Real purge_enable(start = 1) "1 = purge allowed, 0 = purge valve disabled";

  Real T(start = 303.15, fixed = true) "K";
  Real lam(start = 6, fixed = true);
  Real w(start = 0.25*w_n, fixed = true) "compressor speed, rad/s";
  Real p_sm(start = p_amb, fixed = true) "Pa";
  Real z_w(start = 0.1, fixed = true);
  Real z_p(start = 0.2, fixed = true);
  Real m_O2[n](each start = 0.21*p_amb*Vseg/(R_O2*303.15), each fixed = true);
  Real m_N2[n](each start = 0.79*p_amb*Vseg/(R_N2*303.15), each fixed = true);
  Real m_H2a[n](each start = (p_amb + 5000)*Vsa/(R_H2*303.15), each fixed = true) "anode H2 mass per segment, kg";
  Real m_N2a[n](each start = 1e-7, each fixed = true) "anode N2 mass per segment, kg";
  Real W_pump(start = 0, fixed = true) "recirculation pump flow, kg/s";
  Real z_a(start = 0.1, fixed = true) "anode pressure controller integrator";
  Boolean purge(start = false, fixed = true) "purge valve open";

  // cathode channel
  Real p_O2[n], p_N2[n], p[n], y_O2[n], p_a[n], pe[n], wr[n], wk[n];
  Real i_loc[n] "local current density, A/cm2";
  Real E[n], s[n], V_loc[n] "local cell voltage, V";
  Real W_up[n], W_dn[n], Fin_O2[n], Fin_N2[n], Fout_O2[n], Fout_N2[n], Wr[n];
  // anode channel
  Real p_H2a[n], p_N2a[n], p_an[n], y_Ha[n], p_ha[n], ph[n], s_h[n];
  Real Wa_dn[n], Fh_in[n], Fh_out[n], Fn_in[n], Fn_out[n], W_Hc[n], W_x[n];
  // stack and air path
  Real wsum, i_avg, a, lam_eq, sigma, V_cell, V_stack;
  Real r, pr, x_s, W_cp, W_O2_rct, W_ref, e_w, r_raw, r_sat;
  Real p_mean, p_set, e_p, u_raw, u;
  // anode loop scalars
  Real p_an_mean, p_an_set, e_a, u_a_raw, u_inj, W_inj, W_ej, W_H2_dem, W_rec_ref, W_pump_cmd, W_rec, W_purge;
  Real x_N2_out, x_N2_in, dP_mem, W_H2_purge, P_pump;
  Real P_stack, P_cp, P_net, eta_net, OER;
equation
  // ---- cathode channel segments ----
  for k in 1:n loop
    p_O2[k] = m_O2[k]*R_O2*T/Vseg;
    p_N2[k] = m_N2[k]*R_N2*T/Vseg;
    p[k] = p_O2[k] + p_N2[k];
    y_O2[k] = m_O2[k]/(m_O2[k] + m_N2[k]);
    p_a[k] = p_O2[k]/p_amb;
    pe[k] = sqrt(p_a[k]^2 + 1e-4);
    wr[k] = pe[k]^gam*ph[k]^gam_h;
    wk[k] = wr[k]/(wsum/n);
    i_loc[k] = i_avg*wk[k];
    E[k] = 1.229 - 0.85e-3*(T - 298.15) + R*T/(2*F)*log(ph[k]*sqrt(pe[k]));
    s[k] = 1 - i_loc[k]*p_ref/(ilim*pe[k]);
    V_loc[k] = E[k] - R*T/(alpha*F)*log((i_loc[k] + iloss)/(i0*pe[k]/p_ref))
               - i_loc[k]*(tm/sigma + Rc) + c*log(0.5*(s[k] + sqrt(s[k]^2 + 4*eps^2)))
               + c_a*log(0.5*(s_h[k] + sqrt(s_h[k]^2 + 4*eps^2)));
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
  // ---- anode channel segments (same index = same position along the flow, co-flow) ----
  for k in 1:n loop
    p_H2a[k] = m_H2a[k]*R_H2*T/Vsa;
    p_N2a[k] = m_N2a[k]*R_N2*T/Vsa;
    p_an[k] = p_H2a[k] + p_N2a[k];
    y_Ha[k] = m_H2a[k]/(m_H2a[k] + m_N2a[k]);
    p_ha[k] = p_H2a[k]/p_amb;
    ph[k] = sqrt(p_ha[k]^2 + 1e-4);
    s_h[k] = 1 - i_loc[k]*p_href/(ilim_a*ph[k]);
    Fh_out[k] = y_Ha[k]*Wa_dn[k];
    Fn_out[k] = (1 - y_Ha[k])*Wa_dn[k];
    W_Hc[k] = N*M_H2/(2*F)*I_load*wk[k]/n*tanh(p_ha[k]/p_lim);
    W_x[k] = k_cross/n*(p_N2[k] - p_N2a[k]);
    der(m_H2a[k]) = Fh_in[k] - Fh_out[k] - W_Hc[k];
    der(m_N2a[k]) = Fn_in[k] - Fn_out[k] + W_x[k];
  end for;
  for k in 1:n - 1 loop
    Wa_dn[k] = k_seg_a*(p_an[k] - p_an[k + 1]);
  end for;
  Wa_dn[n] = W_rec + W_purge;
  Fh_in[1] = W_inj + y_Ha[n]*W_rec;
  Fn_in[1] = (1 - y_Ha[n])*W_rec;
  for k in 2:n loop
    Fh_in[k] = Fh_out[k - 1];
    Fn_in[k] = Fn_out[k - 1];
  end for;
  // ---- injector, ejector, recirculation pump ----
  p_an_mean = sum(p_an)/n;
  p_an_set = p_mean + dp_an;
  e_a = (p_an_set - p_an_mean)/1e5;
  u_a_raw = Kpa*e_a + Kia*z_a;
  u_inj = min(1.0, max(0.0, u_a_raw));
  der(z_a) = e_a + Kaw*(u_inj - u_a_raw);
  W_inj = u_inj*k_inj*(p_tank - p_an[1]);
  W_ej = ER_n*W_inj*W_inj/(W_inj + W_half);
  W_H2_dem = N*M_H2*I_load/(2*F);
  W_rec_ref = (SR_ref - 1)*W_H2_dem;
  W_pump_cmd = max(0, W_rec_ref - W_ej);
  tau_pump*der(W_pump) = W_pump_cmd - W_pump;
  W_rec = W_ej + W_pump;
  // ---- purge with hysteresis on outlet N2 fraction ----
  x_N2_out = p_N2a[n]/p_an[n];
  x_N2_in = p_N2a[1]/p_an[1];
  when x_N2_out > x_hi and purge_enable > 0.5 then
    purge = true;
  elsewhen x_N2_out < x_lo or purge_enable < 0.5 then
    purge = false;
  end when;
  W_purge = if purge then k_purge*(p_an[n] - p_amb) else 0;
  W_H2_purge = y_Ha[n]*W_purge;
  dP_mem = p_an_mean - p_mean;
  P_pump = W_pump*R_H2*T/p_an_mean*dp_pump/eta_pump;
  // ---- stack: voltage, thermal, hydration ----
  i_avg = I_load/(A*1e4);
  V_cell = sum(V_loc)/n;
  V_stack = N*V_cell;
  a = min(1.0, a_in + kw*i_avg);
  lam_eq = 0.043 + 17.81*a - 39.85*a^2 + 36.0*a^3;
  der(lam) = (lam_eq - lam)/tau_lambda;
  sigma = (0.005139*lam - 0.00326)*exp(1268*(1/303.15 - 1/T));
  Cth*der(T) = N*I_load*(1.254 - V_cell) - hA*(T - Tcool);
  // ---- compressor, manifold, OER controller ----
  r = w/w_n;
  pr = p_sm/p_amb;
  x_s = (pr - 1)/(pr_gain*r^2);
  W_cp = W_n*r*(1 - x_s^2);
  der(p_sm) = R_air*T_sm/V_sm*(W_cp - W_up[1]);
  W_O2_rct = N*I_load/(4*F)*M_O2;
  W_ref = OER_ref*W_O2_rct/0.233;
  e_w = W_ref - W_cp;
  r_raw = Kpw*e_w/W_n + Kiw*z_w;
  r_sat = min(1.05, max(0.15, r_raw));
  der(z_w) = e_w/W_n + Kaw*(r_sat - r_raw);
  der(w) = (r_sat*w_n - w)/tau_cp;
  // ---- cathode pressure controller and valve ----
  p_mean = sum(p)/n;
  p_set = p_amb*(1.15 + 0.45*min(1, I_load/400));
  e_p = (p_mean - p_set)/1e5;
  u_raw = Kpb*e_p + Kib*z_p;
  u = min(1.0, max(0.05, u_raw));
  der(z_p) = e_p + Kaw*(u - u_raw);
  // ---- power and efficiency (LHV, hydrogen fed by the injector) ----
  P_stack = V_stack*I_load;
  P_cp = W_cp*cp_air*T_amb/eta_c*(pr^0.2857 - 1)/eta_m;
  P_net = P_stack - P_cp - P_pump;
  eta_net = P_net/(W_inj*120e6 + 1e-6);
  OER = 0.233*W_up[1]/(W_O2_rct + 1e-9);
end FullSystem;
