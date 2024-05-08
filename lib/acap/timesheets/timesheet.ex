defmodule Acap.Timesheets.Timesheet.TimesheetEntry.Segment do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:start, :stop]}

  embedded_schema do
    field :start, :string
    field :stop, :string
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:start, :stop])
    |> validate_required([:start])
  end
end

defmodule Acap.Timesheets.Timesheet.TimesheetEntry do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__.Segment

  @derive {Jason.Encoder, only: [:day, :hours, :notes]}

  embedded_schema do
    field :day, :date
    field :hours, :float
    field :notes, :string
    embeds_many :segments, Segment, on_replace: :delete
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:day, :hours, :notes])
    |> validate_required([:day])
    |> cast_embed(:segments,
      sort_param: :segments_sort,
      drop_param: :segments_drop,
      with: &Segment.changeset/2
    )
  end
end

defmodule Acap.Timesheets.Timesheet do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__.TimesheetEntry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "timesheets" do
    field :status, Ecto.Enum, values: [:draft, :submitted, :accepted, :rejected], default: :draft
    field :week_starting, :date
    belongs_to :user, Acap.Accounts.User
    embeds_many :entries, TimesheetEntry, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(timesheet, attrs) do
    timesheet
    |> cast(attrs, [:week_starting, :status, :user_id])
    |> cast_embed(:entries,
      sort_param: :entries_sort,
      drop_param: :entries_drop,
      with: &TimesheetEntry.changeset/2,
      required: true
    )
    |> validate_required([:week_starting, :status])
    |> unique_constraint(:week_starting,
      name: :timesheets_week_starting_user_id_index,
      message:
        "You already have a timesheet for this date. You can only save one timesheet per work week."
    )
  end
end
