within FCDT.Tests;
model FullLoadStepTest "100 A to 350 A at t = 100 s; purge enabled"
  FCDT.Systems.FullSystem s;
equation
  s.I_load = if time < 100 then 100 else 350;
  s.OER_ref = 2.0;
  s.purge_enable = 1;
end FullLoadStepTest;
