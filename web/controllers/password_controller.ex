defmodule CercleApi.PasswordController do
  use CercleApi.Web, :controller

  alias CercleApi.{ User, Repo, Mailer }

  def forget_password(conn, _) do
    conn
    |> render(:forget_password)
  end

  def reset_password(conn, %{"user" => %{"email" => email}}) do
    user = Repo.get_by(User, login: email)

    if user do
      length = 40
      random_string = :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
      changeset = User.changeset(user, %{password_reset_code: random_string})

      case Repo.update(changeset) do
        {:ok, user} ->
          password_reset_mail = %Mailman.Email{
            subject: "Reset password",
            from: "referral@cercle.co",
            to: [user.login],
            html: Phoenix.View.render_to_string(CercleApi.EmailView, "password_reset.html", user: user)
          }
				  Mailer.deliver password_reset_mail

          conn
          |> put_flash(:info, "Password reset link has been sent to your email address.")
          |> redirect(to: session_path(conn, :new))
        {:error, changeset} ->
          conn
          |> put_flash(:error, "Unable to generate password reset code")
          |> redirect(to: "/")
      end
    else
      conn
      |> put_flash(:error, "Invalid email")
      |> redirect(to: "/")
    end
  end

  def confirm(conn, %{"password_reset_code" => password_reset_code}) do
    user = Repo.get_by(User, password_reset_code: password_reset_code)

    if user do
      conn
      |> render("confirm.html", user: user)
    else
      conn
      |> put_flash(:error, "Invalid reset link")
      |> redirect(to: "/")
    end
  end

  def confirm_submit(conn, %{"password_reset_code" => password_reset_code, "user" => %{"password" => password}}) do
    user = Repo.get_by(User, password_reset_code: password_reset_code)

    if user do
      changeset = User.registration_changeset(user, %{password: password, password_reset_code: ""})

      case Repo.update(changeset) do
        {:ok, user} ->
          conn
          |> put_flash(:info, "Password updated, please login")
          |> redirect(to: session_path(conn, :new))
        {:error, changeset} ->
          conn
          |> put_flash(:error, "Unable to update password")
          |> redirect(to: "/")
      end
    else
      conn
      |> put_flash(:error, "Invalid reset link")
      |> redirect(to: "/")
    end
  end
end
