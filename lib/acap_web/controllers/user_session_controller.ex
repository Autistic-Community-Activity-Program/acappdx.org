defmodule AcapWeb.UserSessionController do
  use AcapWeb, :controller

  alias Acap.Accounts
  alias AcapWeb.UserAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do

      if user.totp_secret do
        conn
        |> put_session(:pending_2fa, user.id)
        |> put_flash(:info, "Enter the 2FA code")
        |> redirect(to: ~p"/users/log_in/2fa")
      else
        conn
        |> put_flash(:info, "Welcome back!")
        |> UserAuth.log_in_user(user, user_params)
      end
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, :new, error_message: "Invalid email or password")
    end
  end

  def verify(conn, %{"user" => %{"totp_check" => totp_secret_check}}) do

    %{totp_secret: secret} = user = get_session(conn, :pending_2fa) |> Accounts.get_user!()
    if NimbleTOTP.valid?(secret |> Base.decode32!(padding: false), totp_secret_check) do
      conn
        |> delete_session(:pending_2fa)
        |> put_flash(:info, "Welcome back!")
        |> UserAuth.log_in_user(user)
    else
      render(conn, :verify, error_message: "Not valid")
    end
  end

  def verify(conn, _) do
    render(conn, :verify, error_message: nil)
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
