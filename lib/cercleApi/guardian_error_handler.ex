defmodule CercleApi.GuardianErrorHandler do
  import Plug.Conn
  import CercleApi.Router.Helpers

  def unauthenticated(conn, _params) do
    conn
    |> Plug.Conn.put_session(:redirect_url, conn.request_path)
    |> Phoenix.Controller.put_flash(:error, "You must be logged in to access that page.")
    |> Phoenix.Controller.redirect(to: session_path(conn, :new))
  end
end
