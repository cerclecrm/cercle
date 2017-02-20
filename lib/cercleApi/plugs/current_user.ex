defmodule CercleApi.Plugs.CurrentUser do
  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = Guardian.Plug.current_resource(conn)
    Plug.Conn.assign(conn, :current_user, current_user)
  end
end
