within FCDT.Tests;
model StackVoltageTest
  FCDT.Stack.StackVoltage s;
equation
  s.T = 353.15;
  s.pH2 = 1.5;
  s.pO2 = 0.3;
  s.lambda = 12;
  s.I = 45*time;
end StackVoltageTest;
