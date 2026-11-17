within FCDT.Tests;
model FullCoolLoadStepTest "Cold start at 100 A, then 350 A at t = 100 s; full system with the cooling loop"
  FCDT.Systems.FullSystemCool s;
equation
  s.I_load = if time < 100 then 100 else 350;
  s.OER_ref = 2.0;
  s.purge_enable = 1;
  s.filter_enable = 1;
end FullCoolLoadStepTest;
