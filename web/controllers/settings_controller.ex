defmodule CercleApi.SettingsController do
  use CercleApi.Web, :controller

  alias CercleApi.User

  def profile_edit(conn, _params) do
    user = conn.assigns[:current_user]
    changeset = User.changeset(conn.assigns[:current_user])
    if conn.assigns[:current_user].company_id do
      company = CercleApi.Repo.get(CercleApi.Company, conn.assigns[:current_user].company_id)
    end

    conn
    |> put_layout("adminlte.html")
    |> render("profile_edit.html", changeset: changeset, company: company, user: user)
  end

  def profile_update(conn, %{"user" => user_params}) do
    user = conn.assigns[:current_user]
    changeset = User.update_changeset(user, user_params)
    if conn.assigns[:current_user].company_id do
      company = CercleApi.Repo.get(CercleApi.Company, conn.assigns[:current_user].company_id)
    end

    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: "/settings/profile_edit")
      {:error, changeset} ->
        conn
        |> put_layout("adminlte.html")
        |> render("profile_edit.html", changeset: changeset, company: company, user: user)
    end
  end

  def team_edit(conn, _params) do
    company_id = conn.assigns[:current_user].company_id
    company = Repo.get!(CercleApi.Company, company_id) |> Repo.preload [:users]

    conn
    |> put_layout("adminlte.html")
    |> render "team_edit.html", company: company
  end

  def fields_edit(conn, _params) do
    company_id = conn.assigns[:current_user].company_id
    company = Repo.get!(CercleApi.Company, company_id)
    changeset = CercleApi.Company.changeset(company)

    conn
    |> put_layout("adminlte.html")
    |> render "fields_edit.html", company: company, changeset: changeset, settings: true
  end


  def company_edit(conn, _params) do
    company_id = conn.assigns[:current_user].company_id
    company = Repo.get!(CercleApi.Company, company_id)
    changeset = CercleApi.Company.changeset(company)

    conn
    |> put_layout("adminlte.html")
    |> render "company_edit.html", company: company, changeset: changeset, settings: true
  end

  def company_update(conn, _params) do
    company_id = conn.assigns[:current_user].company_id
    company_params = _params["company"]

    company = Repo.get!(CercleApi.Company, company_id)
    changeset = CercleApi.Company.changeset(company, company_params)

    case Repo.update(changeset) do
      {:ok, company} ->
        conn
        |> put_flash(:success, "Company updated successfully.")
        |> redirect(to: "/settings/company_edit")
      {:error, changeset} ->
        render(conn, "company_edit.html", company: company, changeset: changeset, settings: true)
    end
  end


end
