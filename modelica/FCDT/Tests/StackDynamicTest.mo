within FCDT.Tests;
model StackDynamicTest
  FCDT.Stack.StackDynamic s;
equation
  s.pH2 = 1.5;
  s.pO2 = 0.3;
  s.Tcool = 333.15;
  s.a_in = 0.6;
  s.I = if time < 100 then 100 else 350;
end StackDynamicTest;
