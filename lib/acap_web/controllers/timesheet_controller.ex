defmodule AcapWeb.TimesheetController do
  use AcapWeb, :controller

  alias Acap.Accounts
  alias Acap.Timesheets
  alias Acap.Timesheets.Timesheet

  def export(%{assigns: %{current_user: current_user}} = conn, params) do
    filter_date = params |> Map.get("filter_date", nil)
    filter_status = params |> Map.get("filter_status", nil)
    filter_user = params |> Map.get("filter_user", nil)

    timesheets = Timesheets.list_timesheets(current_user, filter_date, filter_status, filter_user)

    case Acap.Exporter.export(timesheets, [:id, :week_starting, :status, :entries, :user]) do
      {:ok, csv_data} ->
        conn
        |> put_resp_content_type("text/csv")
        |> put_resp_header("content-disposition", "attachment; filename=\"timesheets.csv\"")
        |> send_resp(200, csv_data)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to generate CSV: #{reason}")
        |> redirect(to: ~p"/timesheets")
    end
  end

  def index(%{assigns: %{current_user: current_user}} = conn, params) do
    filter_date = params |> Map.get("week_starting", nil)
    filter_status = params |> Map.get("status", nil)
    filter_user = params |> Map.get("user", nil)

    timesheets = Timesheets.list_timesheets(current_user, filter_date, filter_status, filter_user)

    total_pending_timesheets = Timesheets.total_pending_timesheets()
    total_pending_hours = Timesheets.total_pending_hours()
    total_accepted_hours = Timesheets.total_accepted_hours()
    total_accepted_hours_for_current_week = Timesheets.total_accepted_hours_for_current_week()

    all_users = Accounts.list_users()

    weeks_starting_totals = Timesheets.group_hours()
    weeks_starting_totals_accepted = Timesheets.group_accepted_hours()
    weeks_starting_totals_draft = Timesheets.group_draft_hours()
    weeks_starting_totals_submitted = Timesheets.group_submitted_hours()
    weeks_starting_totals_rejected = Timesheets.group_rejected_hours()
    all_starting_weeks = Acap.DateUtils.all_sundays()

    render(conn, :index,
      timesheets: timesheets,
      total_pending_timesheets: total_pending_timesheets,
      total_pending_hours: total_pending_hours,
      total_accepted_hours: total_accepted_hours,
      total_accepted_hours_for_current_week: total_accepted_hours_for_current_week,
      weeks_starting_totals: weeks_starting_totals,
      weeks_starting_totals_draft: weeks_starting_totals_draft,
      weeks_starting_totals_accepted: weeks_starting_totals_accepted,
      weeks_starting_totals_submitted: weeks_starting_totals_submitted,
      weeks_starting_totals_rejected: weeks_starting_totals_rejected,
      all_users: all_users,
      all_starting_weeks: all_starting_weeks,
      filter_date: filter_date,
      filter_status: filter_status,
      filter_user: filter_user
    )
  end

  def new(conn, _params) do
    start_of_week = Date.beginning_of_week(Date.utc_today(), :sunday)

    default_entries =
      for i <- 0..6 do
        %{
          day: Date.add(start_of_week, i),
          hours: 0.0,
          notes: "",
          segments: []
        }
      end

    changeset =
      Timesheets.change_timesheet(%Timesheet{}, %{
        entries: default_entries,
        week_starting: start_of_week
      })

    render(conn, :new, changeset: changeset, assets_js_path: ~p"/assets/timesheet.js")
  end

  def create(%{assigns: %{current_user: current_user}} = conn, %{"timesheet" => timesheet_params}) do
    case Timesheets.create_timesheet(
           timesheet_params
           |> Map.merge(%{"user_id" => current_user.id})
         ) do
      {:ok, timesheet} ->
        conn
        |> put_flash(:info, "Timesheet created successfully.")
        |> redirect(to: ~p"/timesheets/#{timesheet}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, assets_js_path: ~p"/assets/timesheet.js")
    end
  end

  def show(%{assigns: %{current_user: current_user}} = conn, %{"id" => id}) do
    timesheet = Timesheets.get_timesheet!(id, current_user)

    render(conn, :show,
      timesheet: timesheet,
      assets_js_path: ~p"/assets/timesheet_show.js"
    )
  end

  def edit(%{assigns: %{current_user: current_user}} = conn, %{"id" => id}) do
    timesheet = Timesheets.get_timesheet!(id, current_user, :edit)
    changeset = Timesheets.change_timesheet(timesheet)

    render(conn, :edit,
      timesheet: timesheet,
      changeset: changeset,
      assets_js_path: ~p"/assets/timesheet.js"
    )
  end

  def update(%{assigns: %{current_user: current_user}} = conn, %{
        "id" => id,
        "timesheet" => timesheet_params
      }) do
    timesheet = Timesheets.get_timesheet!(id, current_user, :edit)

    case Timesheets.update_timesheet(timesheet, timesheet_params) do
      {:ok, timesheet} ->
        conn
        |> put_flash(:info, "Timesheet updated successfully.")
        |> redirect(to: ~p"/timesheets/#{timesheet}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit,
          timesheet: timesheet,
          changeset: changeset,
          assets_js_path: ~p"/assets/timesheet.js"
        )
    end
  end

  def delete(%{assigns: %{current_user: current_user}} = conn, %{"id" => id}) do
    timesheet = Timesheets.get_timesheet!(id, current_user)
    {:ok, _timesheet} = Timesheets.delete_timesheet(timesheet)

    conn
    |> put_flash(:info, "Timesheet deleted successfully.")
    |> redirect(to: ~p"/timesheets")
  end
end
