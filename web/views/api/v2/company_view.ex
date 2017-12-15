defmodule CercleApi.APIV2.CompanyView do
  use CercleApi.Web, :view

  def render("index.json", %{companies: companies}) do
    %{data: render_many(companies, CercleApi.APIV2.CompanyView, "company.json")}
  end

  def render("show.json", %{company: company}) do
    %{data: render_one(company, CercleApi.APIV2.CompanyView, "company.json")}
  end

  def render("users.json", %{company: company}) do
    %{users: company.users}
  end

  def render("company.json", %{company: company}) do
    %{id: company.id, title: company.title}
  end
end
