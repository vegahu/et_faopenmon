defmodule EtFaopenmon do


  def et_o(tmin, tmax, rhmin, rhmax, wind_speed, sunshine_hours, grad, min, lat, day, month, year, elevation) do
    wind_speed_2m = adjust_wind_speed(to_meters_per_second(wind_speed)) 
    at_pressure = atmosferic_pressure(elevation) 
    gamm = gamma(at_pressure) 
    mean_temp = tmean(tmin, tmax) 
    saturation_vp_min = saturation_vapour_pressure(tmin) 
    saturation_vp_max = saturation_vapour_pressure(tmax) 
    mean_saturation_vp = es(saturation_vp_min, saturation_vp_max) 
    delt = delta(mean_temp) 
    actual_saturation_vp = ea(rhmin, rhmax, saturation_vp_min, saturation_vp_max) 
    deficit_vp = vapor_pressure_deficit(mean_saturation_vp, actual_saturation_vp) 
    albedo = 0.23
    day_numbr = day_number(day, month, year)
    latitude = decimal_degrees_to_radians(grad, min, lat)
    inv_r_distance = ir_distance(day_numbr)
    solar_dec = solar_declination(day_numbr)
    sunset_angl = sunset_angle(latitude, solar_dec)
    ext_radiation = extrater_radiation(inv_r_distance, sunset_angl, solar_dec, latitude)
    dl_hours = daylight_hours(sunset_angl)
    solar_rad = solar_radiation(sunshine_hours, dl_hours, ext_radiation)
    solar_rad_cs = solar_radiation_cs(elevation, ext_radiation)
    solar_rad_net = netsolar_radiation(solar_rad, albedo)
    solar_rad_net_lw = netlongwave_radiation(solar_rad, solar_rad_cs, to_kelvin(tmin), to_kelvin(tmax), actual_saturation_vp)
    net_rad = net_radiation(solar_rad_net, solar_rad_net_lw)

    numerator = 0.408 * delt * net_rad + (gamm * 900 * wind_speed_2m * deficit_vp) / (mean_temp + 273)
    denominator = delt + gamm * (1 + 0.34 * wind_speed_2m)

    Float.round(numerator / denominator, 2)
  end

  @doc """
  Converts speed in km/h to m/s
  """
  def to_meters_per_second(kilometers_per_hour) do
    Float.round((kilometers_per_hour * 1000) / 3600, 2)
  end

  def to_kelvin(temp) do
    temp + 273.16
  end

  @doc """
  (u2)
  Transform the wind speed at the standard 10 meters above the surface in meteorology , because  for the calculation of evapotranspiration wind speed measured at 2 m above the surface is required.
  Units: m/s
  """
  def adjust_wind_speed(wind_speed) do
    conversion_factor = 4.87 / :math.log(67.8 * 10 - 5.42)
    Float.round(wind_speed * conversion_factor, 3)
  end

  @doc """
  Atmospheric pressure (P)

  Units:
  atmospheric pressure [kPa]
  elevation above sea level [m]

  """
  def atmosferic_pressure(elevation) do
    Float.round( 101.3 * :math.pow((293 - 0.0065 * elevation) / 293, 5.26), 1)
  end

  @doc """
  Mean daily air temperature
  """
  def tmean(tmin, tmax) do
    (tmax + tmin) / 2
  end

  @doc """
  Slope of saturation vapour pressure curve (D)
  """
  def delta(mean_temp) do
    power = 17.27 * mean_temp / (mean_temp + 237.3)
    numerator = 4098 * 0.6108 * :math.pow(2.7183, power)
    denominator = :math.pow(mean_temp + 237.3, 2)
    Float.round(numerator / denominator, 3)
  end

  @doc """
  Psychrometric constant (g)
  """
  def gamma(pressure) do
    Float.round(0.665 * :math.pow(10, -3) * pressure, 4)
  end

  @doc """
  Vapour pressure deficit (es - ea) 
  """
  def vapor_pressure_deficit(mean_saturation_vp, actual_saturation_vp) do
    Float.round(mean_saturation_vp - actual_saturation_vp, 3)
  end

  @doc """
  Mean saturation vapour pressure (es)
  """
  def es(saturation_vp_min, saturation_vp_max) do
    Float.round((saturation_vp_max + saturation_vp_min) / 2, 3)
  end

  @doc """
 Actual vapour pressure (ea) derived from relative humidity data
  """
  def ea(rhmin, rhmax, saturation_vp_min, saturation_vp_max) do
    Float.round(((saturation_vp_min * rhmax / 100) + (saturation_vp_max * rhmin / 100)) / 2, 3)
  end

  @doc """
  Saturation vapour pressure (eo)
  """
  def saturation_vapour_pressure(temperature) do
    power = 17.27 * temperature / (temperature + 237.3)
    Float.round(0.6108 * :math.pow(2.7183, power), 3)
  end

#  RADIATION

  @doc """
  Extraterrestrial radiation for daily periods (Ra)
  """
  def extrater_radiation(inv_r_distance, sunset_angl, solar_dec, latitude) do
    g_sc = 0.0820
    Float.round((24 * 60 / :math.pi) * g_sc * inv_r_distance * (sunset_angl * :math.sin(latitude) * :math.sin(solar_dec) + :math.cos(latitude) * :math.cos(solar_dec) * :math.sin(sunset_angl)) ,1)    
  end

  @doc """
  Solar radiation (Rs) 
  Where no actual solar radiation data are available and no calibration has been carried out 
  for improved as and bs parameters, the values as = 0.25 and bs = 0.50 are recommended.
  """
  def solar_radiation(sunshine_hours, dl_hours, ext_radiation) do
    Float.round((0.25 + (0.50 * (sunshine_hours / dl_hours))) * ext_radiation, 2)
  end

  @doc """
  Clear-sky solar radiation (Rso) 

  when calibrated values for as and bs are not available
  
  """
  def solar_radiation_cs(elevation, ext_radiation) do
    Float.round((0.75 + 2.0e-5 * elevation) * ext_radiation, 1)
  end

  @doc """
  Net solar or net shortwave radiation (Rns)
  """
  def netsolar_radiation(solar_rad, albedo) do
    Float.round((1 - albedo) * solar_rad, 2)
  end

  @doc """
  Net longwave radiation (Rnl)
  """
  def netlongwave_radiation(solar_rad, solar_radiation_cs, tmink, tmaxk, actual_saturation_vp) do  
    s = 4.903e-9   
    fact_1 = s * (:math.pow(tmaxk, 4) + :math.pow(tmink, 4)) / 2
    fact_2 = 0.34 - (0.14 * :math.sqrt(actual_saturation_vp))
    fact_3 = (1.35 * (solar_rad / solar_radiation_cs)) - 0.35
    Float.round(fact_1 * fact_2 * fact_3, 2)
  end

  @doc """
  Net radiation (Rn)
  """
  def net_radiation(solar_rad_net, solar_rad_net_lw) do
    Float.round(solar_rad_net - solar_rad_net_lw, 2)
  end



  @doc """
  Daylight hours (N)
  """
  def daylight_hours(sunset_angl) do
    Float.round(24 * sunset_angl / :math.pi, 1)
  end

  @doc """
  Number of the day in the year (J)
  """

  def day_number(day, month, year) when month < 3 do
    day_number_l(day, month, year, :is_not)
  end

  def day_number(day, month, year) when month > 2 do
    day_number_l(day, month, year, leap_year?(year))
  end


  defp day_number_l(day, month, year, false) do
    Float.floor(275 * month/9 - 30 + day) - 2
  end

  defp day_number_l(day, month, year, true) do
    Float.floor(275 * month/9 - 30 + day) - 1
  end

  defp day_number_l(day, month, year, _is_leap) do
    Float.floor.(275 * month/9 - 30 + day)
  end

  defp leap_year?(year) do
    rem(year, 4) == 0 and ((rem(year, 100) != 0) or (rem(year, 400) ==0))
  end

  @doc """
  Conversion from decimal degrees to radians used for latitude
  """
  def decimal_degrees_to_radians(grad, min, "N") do
    degrees = grad + min / 60
    Float.round((:math.pi / 180) * degrees, 3)
  end

  def decimal_degrees_to_radians(grad, min, "S") do
    degrees = grad + min / 60
    - Float.round((:math.pi / 180) * degrees, 3)
  end

  @doc """
  Inverse relative distance Earth-Sun, dr
  """
  def ir_distance(day_numbr) do
    Float.round(1 + 0.033 * :math.cos((2 * :math.pi * day_numbr)/365), 3)
  end

  @doc """
  Solar declination, d
  """
  def solar_declination(day_numbr) do
    Float.round(0.409 * :math.sin((2 * :math.pi * day_numbr / 365) - 1.39), 3)
  end

  @doc """
  sunset hour angle, ws
  """

  def sunset_angle(latitude, solar_dec) do
    Float.round(:math.acos(-1 * :math.tan(latitude) * :math.tan(solar_dec)), 3)
  end

end
