defmodule AcapWeb.TimesheetControllerTest do
  use AcapWeb.ConnCase

  import Acap.TimesheetsFixtures

  @create_attrs %{status: :draft, week_starting: ~D[2024-04-28], entries: %{}}
  @update_attrs %{status: :submitted, week_starting: ~D[2024-04-29], entries: %{}}
  @invalid_attrs %{status: nil, week_starting: nil, entries: nil}

  describe "index" do
    test "lists all timesheets", %{conn: conn} do
      conn = get(conn, ~p"/timesheets")
      assert html_response(conn, 200) =~ "Listing Timesheets"
    end
  end

  describe "new timesheet" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/timesheets/new")
      assert html_response(conn, 200) =~ "New Timesheet"
    end
  end

  describe "create timesheet" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/timesheets", timesheet: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/timesheets/#{id}"

      conn = get(conn, ~p"/timesheets/#{id}")
      assert html_response(conn, 200) =~ "Timesheet #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/timesheets", timesheet: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Timesheet"
    end
  end

  describe "edit timesheet" do
    setup [:create_timesheet]

    test "renders form for editing chosen timesheet", %{conn: conn, timesheet: timesheet} do
      conn = get(conn, ~p"/timesheets/#{timesheet}/edit")
      assert html_response(conn, 200) =~ "Edit Timesheet"
    end
  end

  describe "update timesheet" do
    setup [:create_timesheet]

    test "redirects when data is valid", %{conn: conn, timesheet: timesheet} do
      conn = put(conn, ~p"/timesheets/#{timesheet}", timesheet: @update_attrs)
      assert redirected_to(conn) == ~p"/timesheets/#{timesheet}"

      conn = get(conn, ~p"/timesheets/#{timesheet}")
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, timesheet: timesheet} do
      conn = put(conn, ~p"/timesheets/#{timesheet}", timesheet: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Timesheet"
    end
  end

  describe "delete timesheet" do
    setup [:create_timesheet]

    test "deletes chosen timesheet", %{conn: conn, timesheet: timesheet} do
      conn = delete(conn, ~p"/timesheets/#{timesheet}")
      assert redirected_to(conn) == ~p"/timesheets"

      assert_error_sent 404, fn ->
        get(conn, ~p"/timesheets/#{timesheet}")
      end
    end
  end

  defp create_timesheet(_) do
    timesheet = timesheet_fixture()
    %{timesheet: timesheet}
  end
end
