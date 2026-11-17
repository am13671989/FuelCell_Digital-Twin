within FCDT.Tests;
model ChannelLoadStepTest "100 A to 350 A at t = 100 s, normal OER setpoint"
  FCDT.Air.AirPathChannelSystem s;
equation
  s.I_load = if time < 100 then 100 else 350;
  s.OER_ref = 2.0;
end ChannelLoadStepTest;
