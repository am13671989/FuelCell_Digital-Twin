within FCDT.Tests;
model CoolingIonNoFilterTest "Same as CoolingIonTest but the filter valve is kept closed"
  extends CoolingIonTest(filt = 0);
end CoolingIonNoFilterTest;
