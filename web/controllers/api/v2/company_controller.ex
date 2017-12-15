defmodule CercleApi.APIV2.CompanyController do
  use CercleApi.Web, :controller

  alias CercleApi.Company

  plug CercleApi.Plug.EnsureAuthenticated

  plug :scrub_params, "company" when action in [:create, :update]

  def index(conn, _params) do
    current_user = CercleApi.Plug.current_user(conn)
    companies = CercleApi.Company.user_companies(current_user)
    render(conn, "index.json", companies: companies)
  end

  def create(conn, %{"company" => company_params}) do
    changeset = Company.changeset(%Company{}, company_params)
    case Repo.insert(changeset) do
      {:ok, company} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", company_path(conn, :show, company))
        |> render("show.json", company: company)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CercleApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    company = Repo.get!(Company, id)
    render(conn, "show.json", company: company)
  end

  def update(conn, %{"id" => id, "company" => company_params}) do
    company = Repo.get!(Company, id)
    changeset = Company.changeset(company, company_params)
    case Repo.update(changeset) do
      {:ok, company} ->
        render(conn, "show.json", company: company)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CercleApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    company = Repo.get!(Company, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(company)

    send_resp(conn, :no_content, "")
  end

  def users(conn, _params) do
    company = conn
    |> current_company()
    |> Repo.preload(:users)
    render(conn, "users.json", company: company)
  end
end
