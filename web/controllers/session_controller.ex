defmodule CercleApi.SessionController do
  use CercleApi.Web, :controller
  alias CercleApi.User

  def new(conn, _) do
    conn
    |> render(:new)
  end

  def create(conn, %{"login" => login, "password" => pass, "time_zone" => time_zone}) do
    case CercleApi.Session.authenticate(login, pass, time_zone) do
      {:ok, user} ->
        path = get_session(conn, :redirect_url) || "/activity"
        conn
        |> put_flash(:info, "Welcome back!")
        |> Guardian.Plug.sign_in(user)
        |> redirect(to:  path)

      :error ->
        conn
        |> put_flash(:error, "Invalid username/password combination")
        |> render(:new)
    end
  end

  def delete(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_flash(:info, "You have been logged out")
    |> redirect(to: session_path(conn, :new))
  end
end
