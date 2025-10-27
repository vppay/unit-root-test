# unit-root-test

# to conduct various unit root test, add these commands after (,)

noconstant
constant (default)
trend
drift

# example

# Phillips–Perron unit-root test for y using tsset data
 pperron y
 #Same as above, and include a trend in the specification
 pperron y, trend
 #Same as above, but use 10 lags when calculating Newey–West standard errors
 pperron y, trend lags(10)
 #Same as above, but without a trend or constant in the specification
 pperron y, lags(10) noconstant
