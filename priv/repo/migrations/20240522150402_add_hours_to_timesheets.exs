defmodule Acap.Repo.Migrations.AddHoursToTimesheets do
  use Ecto.Migration

  def change do
    alter table(:timesheets) do
      add :hours, :float, default: 0.0
    end
  end
end
