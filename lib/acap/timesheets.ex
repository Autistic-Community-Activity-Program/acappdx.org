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
  def list_timesheets(%{admin: true}) do
    query =
      from t in Timesheet,
        select: t,
        preload: [:user]

    Repo.all(query)
  end

  def list_timesheets(%{id: user_id}) do
    # get where user is same
    query =
      from t in Timesheet,
        where: t.user_id == ^user_id,
        select: t,
        preload: [:user]

    Repo.all(query)
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
  def get_timesheet!(id, %{id: user_id, admin: true}, :edit) do
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

  def total_pending_timesheets() do
    q =
      from t in Timesheet,
        select: count(t.id),
        where: t.status == :submitted

    [total] = Repo.all(q)
    total || 0
  end
  def total_pending_hours() do
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
  def total_accepted_hours() do
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
end
