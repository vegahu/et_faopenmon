defmodule EtFaopenmonTest do
  use ExUnit.Case
  doctest EtFaopenmon

  test "reference evapotranspiration (ETo) datos diarios" do

    # Example 18:
    # Meteorological data as measured on 6 July in Uccle (Brussels, Belgium)
    # located at 50°48'N and at 100 m above sea level:

    # et_o(alt,tmax,tmin,rhmax,rhmin,ws,sh)

    # alt = 100 m
    # Tmax = 21,5 ºC
    # Tmin = 12,3 ºC
    # RHmax = 84%
    # RHmin = 63%
    # Wind speed measured at 10 m height = 10 km/h
    # Actual hours of sunshine (n) = 9,25 h

    assert EtFaopenmon.et_o(100, 21.5, 12.3, 84, 63, 10, 9.25) == nil #3.88
  end

  test "km/h to m/s" do
    assert EtFaopenmon.to_meters_per_second(10) == 2.78
  end

  test "adjust_wind_speed" do
    assert EtFaopenmon.adjust_wind_speed(EtFaopenmon.to_meters_per_second(10), 10) == 2.079
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

  test "Vapour pressure deficit" do
    assert EtFaopenmon.vapor_pressure_deficit(12.3, 21.5, 63, 84) == 0.589
  end

  test "day number" do
    assert EtFaopenmon.day_number(6, 7, 2015) == 187
  end

  #test "Extraterrestrial radiation for daily periods (Ra)" do
  #  assert EtFaopenmon.extrater_radiation(day, latitude, solar_decimation) == 32.2 
  #end

  test "Conversion of latitude in degrees and minutes to radians" do
    assert EtFaopenmon.decimal_degrees_to_radians(13, 44, "N") == 0.240
  end

  test "inverse relative distance Earth-Sun, dr" do
    assert EtFaopenmon.ir_distance(3, 9, 2015) == 0.985
  end






end
