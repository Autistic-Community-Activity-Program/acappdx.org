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
    |> validate_date_range()
  end

  defp validate_date_range(changeset = %Ecto.Changeset{valid?: true}) do
    start_time = changeset |> get_field(:start)
    stop_time = changeset |> get_field(:stop)

    if start_time && stop_time do
      {:ok, start_struct} = Time.from_iso8601(start_time <> ":00")
      {:ok, stop_struct} = Time.from_iso8601(stop_time <> ":00")

      # Compare times
      if Time.compare(start_struct, stop_struct) != :gt do
        changeset
      else
        changeset |> add_error(:stop, "Stop time can't come before the start time.")
      end
    else
      changeset
    end
  end

  defp validate_date_range(cs), do: cs
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
    |> validate_no_overlap_of_segments()
    |> calc_total_time_in_hours()
  end

  defp validate_no_overlap_of_segments(%Ecto.Changeset{valid?: true} = cs) do
    segments =
      cs
      |> get_field(:segments)
      |> Enum.reject(&(!&1.stop))

    case check_overlaps(segments) do
      :ok ->
        cs

      {:error, {start, stop}} ->
        add_error(cs, :notes, "Segment #{start} - #{stop} overlaps with another segment")
    end
  end

  defp validate_no_overlap_of_segments(cs), do: cs

  defp check_overlaps(segments) do
    with_combinations(segments, fn [a, b] ->
      if time_overlap?(a, b), do: {:error, {a.start, a.stop}}, else: nil
    end) || :ok
  end

  defp with_combinations([], _func), do: nil

  defp with_combinations([head | tail], func) do
    Enum.reduce(tail, nil, fn x, acc ->
      acc || func.([head, x])
    end) || with_combinations(tail, func)
  end

  defp time_overlap?(%{start: start_a, stop: stop_a}, %{start: start_b, stop: stop_b}) do
    start_a = Time.from_iso8601!(start_a <> ":00")
    stop_a = Time.from_iso8601!(stop_a <> ":00")
    start_b = Time.from_iso8601!(start_b <> ":00")
    stop_b = Time.from_iso8601!(stop_b <> ":00")

    Time.compare(start_a, stop_b) == :lt && Time.compare(stop_a, start_b) == :gt
  end

  defp calc_total_time_in_hours(%Ecto.Changeset{valid?: true} = cs) do
    segments =
      cs
      |> get_field(:segments)
      |> Enum.reject(&(!&1.stop))

    total_hours =
      segments
      |> Enum.reduce(0.0, fn %{start: start, stop: stop}, acc ->
        start_time = Time.from_iso8601!(start <> ":00")
        stop_time = Time.from_iso8601!(stop <> ":00")

        duration_in_hours = (Time.diff(stop_time, start_time) / 3600) |> Float.round(2)
        acc + duration_in_hours
      end)

    put_change(cs, :hours, total_hours)
  end

  defp calc_total_time_in_hours(cs), do: cs
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
