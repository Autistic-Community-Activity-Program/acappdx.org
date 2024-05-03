defmodule AcapWeb.AccountsController do
  use AcapWeb, :controller

  alias Acap.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end


  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, timesheet: user)
  end


  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "Account deleted successfully.")
    |> redirect(to: ~p"/accounts")
  end
end
