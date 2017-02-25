defmodule CercleApi.RegistrationController do
  use CercleApi.Web, :controller

  alias CercleApi.{ User, Company }

  def new(conn, _params) do
    changeset = User.changeset(%CercleApi.User{})
    conn
    |> render(:new, changeset: changeset)
  end

  def create(conn, %{"user" => registration_params, "company" => company_params}) do
    changeset = Company.changeset(%Company{}, company_params)
    case Repo.insert(changeset) do
      {:ok, company} ->
        registration_params = %{registration_params | "company_id" => company.id}
        changeset = User.registration_changeset(%User{}, registration_params)
        case Repo.insert(changeset) do
          {:ok, user} ->
            conn
            |> Guardian.Plug.sign_in(user)
            |> configure_session(renew: true)
            |> put_flash(:info, "Account created!")
            |> redirect(to: "/opportunity")
          {:error, changeset} ->
            conn
            |> render(:new, changeset: changeset)
        end
      {:error, changeset} ->
        conn
          |> render(:new, changeset: changeset)
    end
  end
end
