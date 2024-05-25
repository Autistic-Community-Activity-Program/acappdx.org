defmodule Acap.Timesheets do
  @moduledoc """
  The Timesheets context.
  """

  import Ecto.Query, warn: false
  alias Acap.Repo

  alias Acap.Timesheets.Timesheet

  @doc """
  Returns the list of timesheets.

  ## Examples

      iex> list_timesheets()
      [%Timesheet{}, ...]

  """
  def list_timesheets(%{admin: true}, filter_date, filter_status, filter_user) do
    query =
      from(t in Timesheet,
        select: t,
        order_by: [desc: t.week_starting],
        preload: [:user]
      )
      |> maybe_filter_date(filter_date)
      |> maybe_filter_status(filter_status)
      |> maybe_filter_user(filter_user)

    Repo.all(query)
  end

  def list_timesheets(%{id: user_id}, filter_date, filter_status, _filter_user) do
    query =
      from(t in Timesheet,
        where: t.user_id == ^user_id,
        select: t,
        order_by: [desc: t.week_starting],
        preload: [:user]
      )
      |> maybe_filter_date(filter_date)
      |> maybe_filter_status(filter_status)

    Repo.all(query)
  end

  defp maybe_filter_date(q, nil), do: q
  defp maybe_filter_date(q, ""), do: q

  defp maybe_filter_date(q, filter_date) do
    filter_date = filter_date |> Date.from_iso8601!()
    where(q, [t], t.week_starting == ^filter_date)
  end

  defp maybe_filter_status(q, nil), do: q
  defp maybe_filter_status(q, ""), do: q

  defp maybe_filter_status(q, "Draft") do
    where(q, [t], t.status == :draft)
  end

  defp maybe_filter_status(q, "Submitted") do
    where(q, [t], t.status == :submitted)
  end

  defp maybe_filter_status(q, "Accepted") do
    where(q, [t], t.status == :accepted)
  end

  defp maybe_filter_status(q, "Rejected") do
    where(q, [t], t.status == :rejected)
  end

  defp maybe_filter_user(q, nil), do: q
  defp maybe_filter_user(q, ""), do: q

  defp maybe_filter_user(q, filter_user) do
    where(q, [t], t.user_id == ^filter_user)
  end

  @doc """
  Gets a single timesheet.

  Raises `Ecto.NoResultsError` if the Timesheet does not exist.

  ## Examples

      iex> get_timesheet!(123)
      %Timesheet{}

      iex> get_timesheet!(456)
      ** (Ecto.NoResultsError)

  """
  def get_timesheet!(id, %{admin: true}), do: Repo.get!(Timesheet, id) |> Repo.preload([:user])

  def get_timesheet!(id, %{id: user_id}) do
    query =
      from t in Timesheet,
        where: t.user_id == ^user_id,
        where: t.id == ^id,
        select: t,
        preload: [:user]

    Repo.one!(query)
  end

  # Admins can get any for edits
  def get_timesheet!(id, %{admin: true}, :edit) do
    query =
      from t in Timesheet,
        where: t.id == ^id,
        select: t,
        preload: [:user]

    Repo.one!(query)
  end

  # Normal users can only get non accepted for edits
  def get_timesheet!(id, %{id: user_id}, :edit) do
    query =
      from t in Timesheet,
        where: t.user_id == ^user_id,
        where: t.id == ^id,
        where: t.status != :accepted,
        select: t,
        preload: [:user]

    Repo.one!(query)
  end

  @doc """
  Creates a timesheet.

  ## Examples

      iex> create_timesheet(%{field: value})
      {:ok, %Timesheet{}}

      iex> create_timesheet(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_timesheet(attrs \\ %{}) do
    %Timesheet{}
    |> Timesheet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a timesheet.

  ## Examples

      iex> update_timesheet(timesheet, %{field: new_value})
      {:ok, %Timesheet{}}

      iex> update_timesheet(timesheet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_timesheet(%Timesheet{} = timesheet, attrs) do
    timesheet
    |> Timesheet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a timesheet.

  ## Examples

      iex> delete_timesheet(timesheet)
      {:ok, %Timesheet{}}

      iex> delete_timesheet(timesheet)
      {:error, %Ecto.Changeset{}}

  """
  def delete_timesheet(%Timesheet{} = timesheet) do
    Repo.delete(timesheet)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking timesheet changes.

  ## Examples

      iex> change_timesheet(timesheet)
      %Ecto.Changeset{data: %Timesheet{}}

  """
  def change_timesheet(%Timesheet{} = timesheet, attrs \\ %{}) do
    Timesheet.changeset(timesheet, attrs)
  end

  def total_pending_timesheets(%{admin: true}) do
    q =
      from t in Timesheet,
        select: count(t.id),
        where: t.status == :submitted

    [total] = Repo.all(q)
    total || 0
  end

  def total_pending_timesheets(%{id: user_id}) do
    q =
      from t in Timesheet,
        select: count(t.id),
        where: t.status == :submitted,
        where: t.user_id == ^user_id
    [total] = Repo.all(q)
    total || 0
  end

  def total_accepted_hours_for_current_week(%{admin: true}) do
    # Get today's date
    start_of_week = Date.beginning_of_week(Date.utc_today(), :sunday)

    # SQL query that filters timesheets starting from the current Sunday
    sql = """
    SELECT SUM((elem->>'hours')::float) AS total_hours
    FROM timesheets,
    LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
    AND timesheets.status = 'accepted'
    AND timesheets.week_starting = $1
    """

    # Execute the query with the current Sunday as a parameter
    {:ok, %Postgrex.Result{rows: [[total]]}} = Repo.query(sql, [start_of_week])

    # Return the total hours or 0 if nil
    total || 0
  end

  def total_accepted_hours_for_current_week(%{id: user_id}) do
    {:ok, user_id_binary} = Ecto.UUID.dump(user_id)

    # Get today's date
    start_of_week = Date.beginning_of_week(Date.utc_today(), :sunday)

    # SQL query that filters timesheets starting from the current Sunday
    sql = """
    SELECT SUM((elem->>'hours')::float) AS total_hours
    FROM timesheets,
    LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
    AND timesheets.status = 'accepted'
    AND timesheets.week_starting = $1
    AND timesheets.user_id = $2::uuid
    """

    # Execute the query with the current Sunday as a parameter
    {:ok, %Postgrex.Result{rows: [[total]]}} = Repo.query(sql, [start_of_week, user_id_binary])

    # Return the total hours or 0 if nil
    total || 0
  end

  def total_pending_hours(%{admin: true}) do
    sql = """
    SELECT SUM((elem->>'hours')::float) AS total_hours
    FROM timesheets,
    LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
    AND timesheets.status = 'submitted'
    """

    {:ok, %Postgrex.Result{rows: [[total]]}} = Repo.query(sql)

    total || 0
  end


  def total_pending_hours(%{id: user_id}) do
    {:ok, user_id_binary} = Ecto.UUID.dump(user_id)

    sql = """
    SELECT SUM((elem->>'hours')::float) AS total_hours
    FROM timesheets,
    LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
    AND timesheets.status = 'submitted'
    AND timesheets.user_id = $1::uuid
    """

    {:ok, %Postgrex.Result{rows: [[total]]}} = Repo.query(sql, [user_id_binary])

    total || 0
  end

  def total_accepted_hours(%{admin: true}) do
    sql = """
    SELECT SUM((elem->>'hours')::float) AS total_hours
    FROM timesheets,
    LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
    AND timesheets.status = 'accepted'
    """

    {:ok, %Postgrex.Result{rows: [[total]]}} = Repo.query(sql)

    total || 0
  end

  def total_accepted_hours(%{id: user_id}) do
    {:ok, user_id_binary} = Ecto.UUID.dump(user_id)

    sql = """
    SELECT SUM((elem->>'hours')::float) AS total_hours
    FROM timesheets,
    LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
    AND timesheets.status = 'accepted'
    AND timesheets.user_id = $1::uuid
    """

    {:ok, %Postgrex.Result{rows: [[total]]}} = Repo.query(sql, [user_id_binary])

    total || 0
  end

  def group_hours() do
    sql = """
    SELECT
      SUM((elem->>'hours')::float) AS total_hours,
      week_starting
    FROM timesheets,
      LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
    GROUP BY week_starting
    ORDER BY
        week_starting DESC
    """

    {:ok, %Postgrex.Result{rows: weeks_starting_totals}} = Repo.query(sql)
    weeks_starting_totals || []
  end


  def group_accepted_hours(%{admin: true}) do
    sql = """
    SELECT
      SUM((elem->>'hours')::float) AS total_hours,
      week_starting
    FROM timesheets,
      LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
      AND timesheets.status = 'accepted'
    GROUP BY week_starting
    ORDER BY
        week_starting DESC
    """

    {:ok, %Postgrex.Result{rows: weeks_starting_totals}} = Repo.query(sql)
    weeks_starting_totals || []
  end


  def group_accepted_hours(%{id: user_id}) do
    {:ok, user_id_binary} = Ecto.UUID.dump(user_id)
    sql = """
    SELECT
      SUM((elem->>'hours')::float) AS total_hours,
      week_starting
    FROM timesheets,
      LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
      AND timesheets.status = 'accepted'
      AND timesheets.user_id = $1::uuid
    GROUP BY week_starting
    ORDER BY
        week_starting DESC
    """

    {:ok, %Postgrex.Result{rows: weeks_starting_totals}} = Repo.query(sql,[user_id_binary])
    weeks_starting_totals || []
  end



  def group_draft_hours(%{admin: true}) do
    sql = """
    SELECT
      SUM((elem->>'hours')::float) AS total_hours,
      week_starting
    FROM timesheets,
      LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
      AND timesheets.status = 'draft'
    GROUP BY week_starting
    ORDER BY
        week_starting DESC
    """

    {:ok, %Postgrex.Result{rows: weeks_starting_totals}} = Repo.query(sql)
    weeks_starting_totals || []
  end

  def group_draft_hours(%{id: user_id}) do
    {:ok, user_id_binary} = Ecto.UUID.dump(user_id)

    sql = """
    SELECT
      SUM((elem->>'hours')::float) AS total_hours,
      week_starting
    FROM timesheets,
      LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
      AND timesheets.status = 'draft'
      AND timesheets.user_id = $1::uuid
    GROUP BY week_starting
    ORDER BY
        week_starting DESC
    """

    {:ok, %Postgrex.Result{rows: weeks_starting_totals}} = Repo.query(sql, [user_id_binary])
    weeks_starting_totals || []
  end

  def group_submitted_hours(%{admin: true}) do
    sql = """
    SELECT
      SUM((elem->>'hours')::float) AS total_hours,
      week_starting
    FROM timesheets,
      LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
      AND timesheets.status = 'submitted'
    GROUP BY week_starting
    ORDER BY
        week_starting DESC
    """

    {:ok, %Postgrex.Result{rows: weeks_starting_totals}} = Repo.query(sql)
    weeks_starting_totals || []
  end

  def group_submitted_hours(%{id: user_id}) do
    {:ok, user_id_binary} = Ecto.UUID.dump(user_id)

    sql = """
    SELECT
      SUM((elem->>'hours')::float) AS total_hours,
      week_starting
    FROM timesheets,
      LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
      AND timesheets.status = 'submitted'
      AND timesheets.user_id = $1::uuid
    GROUP BY week_starting
    ORDER BY
        week_starting DESC
    """

    {:ok, %Postgrex.Result{rows: weeks_starting_totals}} = Repo.query(sql,[user_id_binary])
    weeks_starting_totals || []
  end

  def group_rejected_hours(%{admin: true}) do
    sql = """
    SELECT
      SUM((elem->>'hours')::float) AS total_hours,
      week_starting
    FROM timesheets,
      LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
      AND timesheets.status = 'rejected'
    GROUP BY week_starting
    ORDER BY
        week_starting DESC
    """

    {:ok, %Postgrex.Result{rows: weeks_starting_totals}} = Repo.query(sql)
    weeks_starting_totals || []
  end

  def group_rejected_hours(%{id: user_id}) do
    {:ok, user_id_binary} = Ecto.UUID.dump(user_id)

    sql = """
    SELECT
      SUM((elem->>'hours')::float) AS total_hours,
      week_starting
    FROM timesheets,
      LATERAL jsonb_array_elements(entries) AS elem
    WHERE elem->>'hours' IS NOT NULL
      AND timesheets.status = 'rejected'
      AND timesheets.user_id = $1::uuid
    GROUP BY week_starting
    ORDER BY
        week_starting DESC
    """

    {:ok, %Postgrex.Result{rows: weeks_starting_totals}} = Repo.query(sql,[user_id_binary])
    weeks_starting_totals || []
  end
end
