within FCDT.Cooling;
model CoolingLoop "Coolant loop: pump, radiator with fan, three-way bypass valve, ion filter with control valve"
  parameter Real cp_c = 3400 "coolant specific heat, J/kg/K";
  parameter Real rho_c = 1050 "coolant density, kg/m3";
  parameter Real cp_a = 1005 "air specific heat, J/kg/K";
  parameter Real T_air = 303.15 "ambient air temperature, K";
  parameter Real C_cs = 68000 "thermal capacity of coolant on the stack side, J/K";
  parameter Real C_rad = 115000 "thermal capacity of the radiator, J/K";
  // pump
  parameter Real m_min = 0.8 "minimum coolant flow, kg/s";
  parameter Real m_max = 5.0 "maximum coolant flow, kg/s";
  parameter Real dT_ref = 8 "target coolant temperature rise across the stack, K";
  parameter Real tau_pc = 1.0 "pump response time constant, s";
  parameter Real k_hyd = 12500 "loop pressure drop coefficient, Pa/(kg/s)^2";
  parameter Real eta_p = 0.5 "pump and motor efficiency";
  // bypass (three-way) valve: u_v = fraction of the flow sent through the radiator
  parameter Real T_set = 333.15 "stack coolant outlet temperature setpoint, K";
  parameter Real Kpv = 0.8, Kiv = 0.03, Kaw = 5.0;
  // radiator and fan
  parameter Real m_air_min = 0.3 "air flow with fan off (ram or natural), kg/s";
  parameter Real m_air_max = 5.0 "air flow with fan at full speed, kg/s";
  parameter Real UA_n = 10000 "radiator UA at maximum air flow, W/K";
  parameter Real P_fan_max = 3000 "fan power at full speed, W";
  parameter Real fan_offset = 1.0 "fan starts this many K above T_set";
  parameter Real fan_band = 4.0 "fan reaches full speed over this many K";
  // ion filter and conductivity
  parameter Real V_loop = 40 "total coolant volume, L";
  parameter Real m_f_max = 0.06 "flow through the ion filter with its valve fully open, kg/s";
  parameter Real kappa_lo = 0.5 "filter valve starts to open above this conductivity, uS/cm";
  parameter Real kappa_hi = 2.0 "filter valve fully open at this conductivity, uS/cm";
  parameter Real eta0 = 0.9 "removal efficiency of fresh resin";
  parameter Real Cap = 5000 "resin capacity, uS/cm * L";
  parameter Real r0 = 0.05 "ion release rate at 60 C, uS/cm per hour";
  parameter Real kappa_start = 1.0 "initial conductivity, uS/cm";
  parameter Real k_iso = 1000 "isolation resistance times conductivity, kOhm * uS/cm";

  input Real Q_st "heat from the stack to the coolant, W";
  input Real V_stack(start = 200) "stack voltage, V";
  input Real filter_enable(start = 1) "1 = filter valve enabled, 0 = closed";

  Real T_cs(start = 303.15, fixed = true) "coolant temperature leaving the stack, K";
  Real T_rad(start = T_air, fixed = true) "radiator coolant temperature, K";
  Real z_v(start = 0, fixed = true) "bypass valve controller integrator";
  Real m_c(start = m_min, fixed = true) "coolant mass flow, kg/s";
  Real kappa(start = kappa_start, fixed = true) "coolant conductivity, uS/cm";
  Real phi(start = 0, fixed = true) "resin saturation, 0 = fresh, 1 = exhausted";

  Real m_ref, e_v, u_raw, u_v, T_ci;
  Real s_f, m_air, UA, C_a, Q_rad, m_cr;
  Real u_f, m_f, eta_f, rem, r_leach;
  Real P_pump, P_fan, P_cool, R_iso, R_req, iso_margin;
equation
  // pump: flow follows the heat to remove
  m_ref = min(m_max, max(m_min, Q_st/(cp_c*dT_ref)));
  tau_pc*der(m_c) = m_ref - m_c;
  // bypass valve: PI control of the stack coolant outlet temperature
  e_v = (T_cs - T_set)/10;
  u_raw = Kpv*e_v + Kiv*z_v;
  u_v = min(1.0, max(0.0, u_raw));
  der(z_v) = e_v + Kaw*(u_v - u_raw);
  m_cr = u_v*m_c;
  T_ci = T_cs + u_v*(T_rad - T_cs);
  // fan and radiator
  s_f = min(1.0, max(0.0, (T_cs - (T_set + fan_offset))/fan_band));
  m_air = m_air_min + (m_air_max - m_air_min)*s_f;
  UA = UA_n*(m_air/m_air_max)^0.6;
  C_a = m_air*cp_a;
  Q_rad = C_a*(1 - exp(-UA/C_a))*(T_rad - T_air);
  // coolant thermal balances
  C_cs*der(T_cs) = m_c*cp_c*(T_ci - T_cs) + Q_st;
  C_rad*der(T_rad) = m_cr*cp_c*(T_cs - T_rad) - Q_rad;
  // ion filter valve (proportional on conductivity), resin, conductivity
  u_f = filter_enable*min(1.0, max(0.0, (kappa - kappa_lo)/(kappa_hi - kappa_lo)));
  m_f = u_f*m_f_max;
  eta_f = eta0*(1 - phi^3);
  rem = (m_f/(rho_c/1000))*eta_f*kappa;
  r_leach = r0*exp(0.07*(T_cs - 333.15));
  der(kappa) = r_leach/3600 - rem/V_loop;
  der(phi) = rem/Cap;
  // power and isolation
  P_pump = k_hyd*m_c^3/(rho_c*eta_p);
  P_fan = P_fan_max*s_f^3;
  P_cool = P_pump + P_fan;
  R_iso = k_iso/kappa;
  R_req = 0.5*max(abs(V_stack), 50);
  iso_margin = R_iso/R_req;
end CoolingLoop;
