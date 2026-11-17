within FCDT.Tests;
model ChannelStarvationTest "200 A constant; OER setpoint forced from 2.0 to 0.8 at t = 80 s (air supply fault)"
  FCDT.Air.AirPathChannelSystem s;
equation
  s.I_load = 200;
  s.OER_ref = if time < 80 then 2.0 else 0.8;
end ChannelStarvationTest;
