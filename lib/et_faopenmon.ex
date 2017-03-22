defmodule EtFaopenmon do


  def et_o(alt, tmax, tmin, rhmax, rhmin, ws, sh) do

  end

  @doc """
  Converts speed in km/h to m/s
  """
  def to_meters_per_second(kilometers_per_hour) do
    Float.round((kilometers_per_hour * 1000) / 3600, 2)
  end

  @doc """
  Transform the wind speed at "elevation" meters above the surface, because  for the calculation of evapotranspiration wind speed measured at 2 m above the surface is required.
  Units: m/s
  """
  def adjust_wind_speed(windspeed, elevation) do
    conversion_factor = 4.87 / :math.log(67.8 * elevation - 5.42)
    Float.round(windspeed * conversion_factor, 3)
  end

  @doc """
  Atmospheric pressure (P)

  Units:
  atmospheric pressure [kPa]
  elevation above sea level [m]

  """
  def atmosferic_pressure(elevation) do
    Float.round( 101.3 * :math.pow((293 - 0.0065 * elevation) / 293, 5.26),1)
  end

  @doc """
  Mean daily air temperature
  """
  def tmean(tmax, tmin) do
    (tmax + tmin)/2
  end

  @doc """
  Slope of saturation vapour pressure curve (D)
  """
  def delta(temperature) do
    power = 17.27 * temperature / (temperature + 237.3)
    numerator = 4098 * 0.6108 * :math.pow(2.7183, power)
    denominator = :math.pow(temperature + 237.3, 2)
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
  def vapor_pressure_deficit(tmin, tmax, hrmin, hrmax) do
    es(tmin, tmax) - ea(tmin, tmax, hrmin, hrmax)
  end

@doc """
  Mean saturation vapour pressure (es)
  """
  def es(tmin, tmax) do
    Float.round((saturation_vapour_pressure(tmax) + saturation_vapour_pressure(tmin)) / 2, 3)

  end

  @doc """
Actual vapour pressure (ea) derived from relative humidity data
  """
  def ea(tmin, tmax, hrmin, hrmax) do
    Float.round(((saturation_vapour_pressure(tmin) * (hrmax / 100)) + (saturation_vapour_pressure(tmax) * (hrmin / 100))) / 2, 3)
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
  def extrater_radiation(grad, min, lat, day, month, year, solar_decimation) do
    latitude = decimal_degrees_to_radians(grad, min, lat)
    day_numb = day_number(day, month, year)
    distance_r = ir_distance(day, month, year)
    solar_dec = solar_declination(day, month, year)
    sunset_ha = sunset_angle(grad, min, lat, day, month, year)
    g_sc = 0.0820
    Float.round((24 * 60 / :math.pi) * g_sc * distance_r * (sunset_ha * :math.sin(latitude) * :math.sin(solar_dec) + :math.cos(latitude) * :math.cos(solar_dec) * :math.sin(sunset_ha)) ,1)    
  end

  @doc """
  Solar radiation (Rs) 

  Where no actual solar radiation data are available and no calibration has been carried out for improved as and bs parameters, the values as = 0.25 and bs = 0.50 are recommended.

  """
  def solar_radiation(grad, min, lat, day, month, year, sunshine_hours, solar_decimation) do
    latitude = decimal_degrees_to_radians(grad, min, lat)
    day_numb = day_number(day, month, year)
    distance_r = ir_distance(day, month, year)
    solar_dec = solar_declination(day, month, year)
    sunset_ha = sunset_angle(grad, min, lat, day, month, year)
    g_sc = 0.0820
    daylight_h = daylight_hours(grad, min, lat, day, month, year)
    ext_radiation = extrater_radiation(grad, min, lat, day, month, year, solar_decimation)
    Float.round((0.25 + (0.50 * (sunshine_hours / daylight_h))) * ext_radiation, 1)
  end

  @doc """
  Clear-sky solar radiation (Rso) 

  when calibrated values for as and bs are not available:
  
  """
  def solar_radiation_cs(grad, min, lat, day, month, year, solar_decimation, elevation) do
    Float.round((0.75 + 2.0e-5 * elevation) * extrater_radiation(grad, min, lat, day, month, year, solar_decimation), 1)
  end

  @doc """
  Net solar or net shortwave radiation (Rns)
  """
  def netsolar_radiation(grad, min, lat, day, month, year, sunshine_hours, solar_decimation, albedo) do
    Float.round((1 - albedo) * solar_radiation(grad, min, lat, day, month, year, sunshine_hours, solar_decimation), 1)
  end

  @doc """
  Net longwave radiation (Rnl)
  """
  def netlongwave_radiation(tmin, tmax, hrmin, hrmax, grad, min, lat, day, month, year, sunshine_hours, solar_decimation, elevation) do
    solar_rad = solar_radiation(grad, min, lat, day, month, year, sunshine_hours, solar_decimation)
    solar_rad_clear = solar_radiation_cs(grad, min, lat, day, month, year, solar_decimation, elevation)
    s = 4.903e-9   
    fact_1 = s * (:math.pow(tmax, 4) + :math.pow(tmin, 4)) / 2
    fact_2 = 0.34 - (0.14 * :math.sqrt(ea(tmin, tmax, hrmin, hrmax)))
    fact_3 = 1.35 * (solar_radiation(grad, min, lat, day, month, year, sunshine_hours, solar_decimation / solar_radiation_cs(grad, min, lat, day, month, year, solar_decimation, elevation) - 0.35))
    Float.round(fact_1 * fact_2 * fact_3, 1)
  end


  @doc """
  Daylight hours (N)
  """
  def daylight_hours(grad, min, lat, day, month, year) do
    sunset_ha = sunset_angle(grad, min, lat, day, month, year)
    Float.round(24 * sunset_ha / :math.pi, 1)
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
  def ir_distance(day, month, year) do
    Float.round(1 + 0.033 * :math.cos((2 * :math.pi * day_number(day, month, year))/365), 3)
  end

  @doc """
  Solar declination, d
  """
  def solar_declination(day, month, year) do
    Float.round(0.409 * :math.sin(((2 * :math.pi * day_number(day, month, year))/365) - 1.39), 3)
  end

  @doc """
  sunset hour angle, ws
  """

  def sunset_angle(grad, min, lat, day, month, year) do
    Float.round(:math.acos(-1 * (:math.tan(decimal_degrees_to_radians(grad, min, lat)) * :math.tan(solar_declination(day, month, year)))), 3)
    
  end





end
