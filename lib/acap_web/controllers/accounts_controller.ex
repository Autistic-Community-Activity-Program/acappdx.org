defmodule AcapWeb.AccountsController do
  use AcapWeb, :controller

  alias Acap.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)

    render(conn, :edit,
      user: user,
      changeset: changeset,
      assets_js_path: ~p"/assets/user.js"
    )
  end

  def update(conn, %{
        "id" => id,
        "user" => user_params
      }) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Account updated successfully.")
        |> redirect(to: ~p"/accounts/#{user}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit,
          user: user,
          changeset: changeset,
          assets_js_path: ~p"/assets/user.js"
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "Account deleted successfully.")
    |> redirect(to: ~p"/accounts")
  end
end
