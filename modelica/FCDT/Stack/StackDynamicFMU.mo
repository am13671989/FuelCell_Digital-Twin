within FCDT.Stack;
model StackDynamicFMU "FMU wrapper: same model with default input values so Python can drive it"
  extends StackDynamic(I(start = 100), pH2(start = 1.5), pO2(start = 0.3),
                       Tcool(start = 333.15), a_in(start = 0.6));
end StackDynamicFMU;
