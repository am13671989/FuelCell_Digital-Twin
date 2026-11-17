within FCDT.Tests;
model AirPathSystemTest
  FCDT.Air.AirPathSystem s;
equation
  s.I_load = if time < 100 then 100 else 350;
end AirPathSystemTest;
