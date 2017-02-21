defmodule CercleApi.CompanyController do
  use CercleApi.Web, :controller

  alias CercleApi.Company

  plug :scrub_params, "company" when action in [:create]

  def create(conn, %{"company" => company_params, "code" => code_params}) do

    changeset = Company.changeset(%Company{}, company_params)

    case Repo.insert(changeset) do
      {:ok, _company} ->

        conn
        |> put_status(:created)
        |> put_resp_header("location", company_path(conn, :show, _company))
        |> render("show.json", company: _company)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CercleApi.ChangesetView, "error.json", changeset: changeset)
    end

  end

	def edit(conn, _params) do
    company_app_secret_key = _params["id"]
    company = Repo.get_by!(CercleApi.Company, app_secret_key: company_app_secret_key)
		changeset = CercleApi.Company.changeset(company)
		conn
		|> put_layout(false)
		|> render("edit.html", company: company, changeset: changeset)
  end

	def update(conn, _params) do
    company_app_secret_key = _params["id"]
    company_params = _params["company"]

    company = Repo.get_by!(CercleApi.Company, app_secret_key: company_app_secret_key)
    changeset = CercleApi.Company.changeset(company, company_params)

    case Repo.update(changeset) do
      {:ok, company} ->
        conn
        |> put_flash(:success, "Company updated successfully.")
        |> redirect(to: "/companies/#{company.app_secret_key}/subscriptions/new")
      {:error, changeset} ->
        code = Repo.get_by(CercleApi.Code, company_id: company.id)
        if code do
          company_code = code.code
        end
        render(conn, "edit.html", company: company, changeset: changeset)
    end
  end
end
