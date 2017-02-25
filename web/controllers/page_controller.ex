defmodule CercleApi.PageController do
  use CercleApi.Web, :controller

  def index(conn, _params) do
    current_user = Guardian.Plug.current_resource(conn)
    if (current_user && is_integer(current_user.company_id) ) do
      conn
        |> redirect(to: "/activity")
        |> halt
    else
      conn
        |> put_layout("app.html")
        |> render("index.html")
    end
  end

end
