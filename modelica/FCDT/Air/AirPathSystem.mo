within FCDT.Air;
model AirPathSystem "Stack + cathode air path: compressor, supply manifold, cathode volume, back-pressure valve, OER and pressure controllers"
  // ---- ambient and constants ----
  parameter Real p_amb = 101325 "Pa";
  parameter Real T_amb = 298.15 "K";
  constant Real R_O2 = 259.8 "J/kg/K";
  constant Real R_N2 = 296.8 "J/kg/K";
  constant Real R_air = 287.0 "J/kg/K";
  constant Real M_O2 = 0.032 "kg/mol";
  constant Real F = 96485;
  // ---- compressor (speed-dependent map + first-order speed lag) ----
  parameter Real w_n = 10472 "nominal speed, rad/s (100000 rpm)";
  parameter Real W_n = 0.10 "flow at nominal speed and pr = 1, kg/s";
  parameter Real pr_gain = 3.0 "pr_max - 1 at nominal speed";
  parameter Real eta_c = 0.70 "compressor isentropic efficiency";
  parameter Real eta_m = 0.90 "motor and inverter efficiency";
  parameter Real tau_cp = 0.15 "speed response time constant, s";
  parameter Real cp_air = 1005 "J/kg/K";
  // ---- manifold, cathode, valve ----
  parameter Real V_sm = 0.02 "supply manifold volume, m3";
  parameter Real T_sm = 330 "supply manifold temperature after intercooler, K";
  parameter Real V_ca = 0.02 "cathode volume, m3";
  parameter Real k_sm = 2.5e-6 "manifold to cathode flow constant, kg/s/Pa";
  parameter Real k_bp = 2.0e-6 "back-pressure valve flow constant at full opening, kg/s/Pa";
  // ---- controllers ----
  parameter Real OER_ref = 2.0 "oxygen excess ratio setpoint";
  parameter Real Kpw = 1.0, Kiw = 3.0 "OER (flow) controller gains";
  parameter Real Kpb = 1.0, Kib = 3.0 "pressure controller gains";
  parameter Real Kaw = 5.0 "anti-windup gain";

  input Real I_load(start = 100) "stack current, A";
  FCDT.Stack.StackDynamic stack;

  Real w(start = 0.25*w_n, fixed = true) "compressor speed, rad/s";
  Real p_sm(start = p_amb, fixed = true) "supply manifold pressure, Pa";
  Real m_O2(start = 0.21*p_amb*V_ca/(R_O2*303.15), fixed = true) "cathode O2 mass, kg";
  Real m_N2(start = 0.79*p_amb*V_ca/(R_N2*303.15), fixed = true) "cathode N2 mass, kg";
  Real z_w(start = 0.1, fixed = true) "OER controller integrator";
  Real z_p(start = 0.2, fixed = true) "pressure controller integrator";

  Real r, pr, pr_max_m1, x_s, W_cp "compressor";
  Real W_sm, W_bp, W_O2_rct, W_ref;
  Real p_O2, p_N2, p_ca, p_ref, y_O2;
  Real e_w, r_raw, r_sat, e_p, u_raw, u;
  Real P_stack, P_cp, P_net, W_H2, eta_net, OER;
equation
  // compressor map
  r = w/w_n;
  pr = p_sm/p_amb;
  pr_max_m1 = pr_gain*r^2;
  x_s = (pr - 1)/pr_max_m1;
  W_cp = W_n*r*(1 - x_s^2);
  // OER controller: flow reference from current
  W_O2_rct = stack.N*I_load/(4*F)*M_O2;
  W_ref = OER_ref*W_O2_rct/0.233;
  e_w = W_ref - W_cp;
  r_raw = Kpw*e_w/W_n + Kiw*z_w;
  r_sat = min(1.05, max(0.15, r_raw));
  der(z_w) = e_w/W_n + Kaw*(r_sat - r_raw);
  der(w) = (r_sat*w_n - w)/tau_cp;
  // supply manifold
  W_sm = k_sm*(p_sm - p_ca);
  der(p_sm) = R_air*T_sm/V_sm*(W_cp - W_sm);
  // cathode (gas at stack temperature; vapor neglected in total pressure)
  p_O2 = m_O2*R_O2*stack.T/V_ca;
  p_N2 = m_N2*R_N2*stack.T/V_ca;
  p_ca = p_O2 + p_N2;
  y_O2 = m_O2/(m_O2 + m_N2);
  der(m_O2) = 0.233*W_sm - y_O2*W_bp - W_O2_rct;
  der(m_N2) = 0.767*W_sm - (1 - y_O2)*W_bp;
  // back-pressure valve and pressure controller
  p_ref = p_amb*(1.15 + 0.45*min(1, I_load/400));
  e_p = (p_ca - p_ref)/1e5;
  u_raw = Kpb*e_p + Kib*z_p;
  u = min(1.0, max(0.05, u_raw));
  der(z_p) = e_p + Kaw*(u - u_raw);
  W_bp = u*k_bp*(p_ca - p_amb);
  // stack connections
  stack.I = I_load;
  stack.pH2 = 1.5;
  stack.pO2 = p_O2/p_amb;
  stack.Tcool = 333.15;
  stack.a_in = 0.6;
  // power and efficiency (LHV basis)
  P_stack = stack.V*I_load;
  P_cp = W_cp*cp_air*T_amb/eta_c*(pr^0.2857 - 1)/eta_m;
  P_net = P_stack - P_cp;
  W_H2 = stack.N*I_load/(2*F)*0.002016;
  eta_net = P_net/(W_H2*120e6);
  OER = 0.233*W_sm/(W_O2_rct + 1e-9);
end AirPathSystem;
