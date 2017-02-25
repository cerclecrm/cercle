defmodule CercleApi.OrganizationsController do
  use CercleApi.Web, :controller

  alias CercleApi.Organization

	require Logger

  def index(conn, _params) do

    company_id = conn.assigns[:current_user].company_id
    company = Repo.get!(CercleApi.Company, company_id) |> Repo.preload([:users])

    query = from p in Organization,
      where: p.company_id == ^company_id,
      order_by: [desc: p.updated_at]
		companies = Repo.all(query)
		conn
		|> put_layout("adminlte.html")
		|> render("index.html", companies: companies, company: company)
  end

  def edit(conn, %{"id" => id}) do
    organization = Repo.get!(Organization, id) |> Repo.preload([:contacts])
    conn
    |> put_layout("adminlte.html")
    |> render("edit.html", organization: organization)
  end

end
