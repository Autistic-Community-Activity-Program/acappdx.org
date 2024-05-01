defmodule Acap.TimesheetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Acap.Timesheets` context.
  """

  @doc """
  Generate a timesheet.
  """
  def timesheet_fixture(attrs \\ %{}) do
    {:ok, timesheet} =
      attrs
      |> Enum.into(%{
        entries: %{},
        status: :draft,
        week_starting: ~D[2024-04-28]
      })
      |> Acap.Timesheets.create_timesheet()

    timesheet
  end
end
