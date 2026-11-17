within FCDT.Tests;
model FullAnodeStarvationTest "200 A; membrane with 5x crossover; purge valve disabled from t = 40 s"
  FCDT.Systems.FullSystem s(k_cross = 1.5e-9);
equation
  s.I_load = 200;
  s.OER_ref = 2.0;
  s.purge_enable = if time < 40 then 1 else 0;
end FullAnodeStarvationTest;
