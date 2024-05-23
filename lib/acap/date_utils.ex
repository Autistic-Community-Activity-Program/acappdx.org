defmodule Acap.DateUtils do
  alias NimbleStrftime
  alias DateTime, as: DT

  def all_sundays do
    # Get today's date
    today = Date.utc_today()

    # Get the current year using year_of_era/1
    {current_year, _} = Date.year_of_era(today)

    # Find the first day of the year
    {:ok, first_day} = Date.new(current_year, 1, 1)

    # Calculate the first Sunday
    first_sunday =
      first_day
      |> Date.day_of_week()
      |> calc_first_sunday(first_day)

    # Generate all Sundays of the year
    Stream.iterate(first_sunday, &Date.add(&1, 7))
    |> Enum.take_while(fn date -> Date.year_of_era(date) |> elem(0) == current_year end)
  end

  defp calc_first_sunday(7, first_day) do
    # If January 1st is a Saturday, the next day is Sunday
    Date.add(first_day, 1)
  end

  defp calc_first_sunday(day_of_week, first_day) do
    # Calculate the number of days to add to get to the next Sunday
    days_to_add = 7 - day_of_week
    Date.add(first_day, days_to_add)
  end

  def convert_utc_to_pst!(utc_datetime) do
    # Adjust the datetime to PST (UTC-8)
    case DT.shift_zone(utc_datetime, "America/Los_Angeles") do
      {:ok, datetime_in_pst} -> datetime_in_pst
      {:error, reason} -> {:error, reason}
    end
  end

  def format_datetime(datetime, format \\ "%Y-%m-%d %H:%M:%S") do
    NimbleStrftime.format(datetime, format)
  end
end
