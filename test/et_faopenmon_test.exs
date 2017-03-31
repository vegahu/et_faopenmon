defmodule EtFaopenmonTest do
  use ExUnit.Case
  doctest EtFaopenmon

  test "reference evapotranspiration (ETo) daily period" do

    # Example 18:
    # Meteorological data as measured on 6 July in Uccle (Brussels, Belgium)
    # located at 50°48'N and at 100 m above sea level:

    # et_o(alt,tmax,tmin,rhmax,rhmin,ws,sh)

    # alt = 100 m
    # Tmax = 21,5 ºC
    # Tmin = 12,3 ºC
    # RHmax = 84%
    # RHmin = 63%
    # Wind speed measured at 10 m height = 10 km/h = 
    # Actual hours of sunshine (n) = 9,25 h

    assert EtFaopenmon.et_o(12.3, 21.5, 63, 84, 10, 9.25, 50, 48, "N", 6, 7, 2015, 100) == 3.88
  end

  test "km/h to m/s" do
    assert EtFaopenmon.to_meters_per_second(10) == 2.78
  end

  
  test "adjust_wind_speed" do
    assert EtFaopenmon.adjust_wind_speed(EtFaopenmon.to_meters_per_second(10)) == 2.079
  end

  test "atomosferic pressure (P)" do
    assert EtFaopenmon.atmosferic_pressure(100) == 100.1
  end

  test "Mean Temperature (Tmeam)" do
    assert EtFaopenmon.tmean(21.5, 12.3) == 16.9
  end

  test "Slope of saturation vapour pressure curve (D)" do
    assert EtFaopenmon.delta(16.9) == 0.122
  end

  test "Psychrometric constant (g)" do
    assert EtFaopenmon.gamma(100.1) == 0.0666
  end

  test "Mean saturation vapour pressure (es)" do
    assert EtFaopenmon.es(1.431, 2.564) == 1.998
  end

  test "Mean saturation vapour pressure (ea)" do
    assert EtFaopenmon.ea(63, 84, 1.431, 2.564) == 1.409
  end



  test "Vapour pressure deficit" do
    assert EtFaopenmon.vapor_pressure_deficit(1.998, 1.409) == 0.589
  end

  test "day number" do
    assert EtFaopenmon.day_number(6, 7, 2015) == 187
  end

# RADIATION

  test "Conversion of latitude in degrees and minutes to radians" do
    assert EtFaopenmon.decimal_degrees_to_radians(50, 48, "N") == 0.887
  end

  test "inverse relative distance Earth-Sun, dr" do
    assert EtFaopenmon.ir_distance(187) == 0.967
  end

  test "Solar declination, d" do
    assert EtFaopenmon.solar_declination(187) == 0.395
  end

  test "sunset hour angle, ws" do
    assert EtFaopenmon.sunset_angle(0.887, 0.395) == 2.108
  end  

  test "Daylight hours (N)" do
    assert EtFaopenmon.daylight_hours(2.108) == 16.1
  end

  test "Extraterrestrial radiation for daily periods (Ra)" do
    assert EtFaopenmon.extrater_radiation(0.967, 2.108, 0.395, 0.887) == 41.1 
  end

  test "Solar radiation (Rs)" do
    assert EtFaopenmon.solar_radiation(9.25, 16.1, 41.1) == 22.08
  end

  test "  Clear-sky solar radiation (Rso)" do
    assert EtFaopenmon.solar_radiation_cs(100, 41.1) == 30.90
  end

  test "Net solar or net shortwave radiation (Rns)" do
    assert EtFaopenmon.netsolar_radiation(22.07, 0.23) == 16.99
  end

  test "Net longwave radiation (Rnl)" do
    assert EtFaopenmon.netlongwave_radiation(22.07, 30.90, 285.5, 294.7, 1.409) == 3.71
  end

  test "Net radiation (Rn)" do
    assert EtFaopenmon.net_radiation(16.99, 3.71) == 13.28
  end  

end
