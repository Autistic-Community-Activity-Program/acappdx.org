defmodule Acap.Repo.Migrations.CreateTimesheets do
  use Ecto.Migration

  def change do
    create table(:timesheets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :week_starting, :date
      add :status, :string
      add :entries, :map
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:timesheets, [:user_id])
    create unique_index(:timesheets, [:week_starting, :user_id])
  end
end
