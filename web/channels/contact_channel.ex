
defmodule CercleApi.ContactChannel do
  use Phoenix.Channel
  require Logger
  alias CercleApi.Contact
  alias CercleApi.Repo

  def join("contacts:" <> contact_id, _message, socket) do
    socket = assign(socket, :contact_id, contact_id)
    Logger.debug "> JOIN JOIN"
    {:ok, socket}
  end

  def handle_in("load_state", _params, socket) do
  	contact = CercleApi.Repo.get(Contact, socket.assigns[:contact_id])
    Logger.debug "> LOAD STATE"

    push socket, "state", contact
    {:noreply, socket}
  end

end