defmodule AcapWeb.UserSettingsController do
  use AcapWeb, :controller

  alias Acap.Accounts
  alias AcapWeb.UserAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    user = conn.assigns.current_user

    user = conn.assigns.current_user
    secret = NimbleTOTP.secret()

    qr_code_uri = NimbleTOTP.otpauth_uri("acappdx.org:#{user.email}", secret)
    {:ok, qr_code_uri} = qr_code_uri |> QRCode.create() |> QRCode.render() |> QRCode.to_base64()

    render(conn, :edit,
      totp_changeset: Accounts.change_user_totp(user),
      qr_code_uri: qr_code_uri,
      totp_secret: secret |> Base.encode32(padding: false)
    )
  end

  def update(conn, %{"action" => "update_totp"} = params) do
    %{"user" => %{"totp_secret" => secret} = user_params} = params

    user = conn.assigns.current_user

    qr_code_uri = NimbleTOTP.otpauth_uri("acappdx.org:#{user.email}", secret)
    {:ok, qr_code_uri} = qr_code_uri |> QRCode.create() |> QRCode.render() |> QRCode.to_base64()


    case Accounts.update_user_totp(user, user_params) do
      {:ok, _applied_user} ->
        conn
        |> put_flash(
          :info,
          "2FA is now enabled for this account"
        )
        |> redirect(to: ~p"/")

      {:error, changeset} ->
        render(conn, :edit, totp_changeset: changeset, qr_code_uri: qr_code_uri, totp_secret: secret)
    end
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: ~p"/users/settings")

      {:error, changeset} ->
        render(conn, :edit, email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, ~p"/users/settings")
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, :edit, password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: ~p"/users/settings")

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
