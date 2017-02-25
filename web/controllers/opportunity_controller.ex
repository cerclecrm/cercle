defmodule CercleApi.OpportunityController do
  use CercleApi.Web, :controller

  alias CercleApi.User
  alias CercleApi.Contact
  alias CercleApi.Organization
  alias CercleApi.Opportunity
  alias CercleApi.TimelineEvent

  alias CercleApi.Company

	require Logger

  def index(conn, _params) do

    company_id = conn.assigns[:current_user].company_id
    company = Repo.get!(CercleApi.Company, company_id) |> Repo.preload [:users]

    query0 = from p in Opportunity,
      where: p.company_id == ^company_id,
      where: p.status == 0,
      where: p.stage == 0,
      order_by: [desc: p.updated_at]

    query1 = from p in Opportunity,
      where: p.company_id == ^company_id,
      where: p.status == 0,
      where: p.stage == 1,
      order_by: [desc: p.updated_at]

    query2 = from p in Opportunity,
      where: p.company_id == ^company_id,
      where: p.status == 0,
      where: p.stage == 2,
      order_by: [desc: p.updated_at]

    query3 = from p in Opportunity,
      where: p.company_id == ^company_id,
      where: p.status == 0,
      where: p.stage == 3,
      order_by: [desc: p.updated_at]

    query4 = from p in Opportunity,
      where: p.company_id == ^company_id,
      where: p.status == 0,
      where: p.stage == 4,
      order_by: [desc: p.updated_at]

    #order_by: [desc: p.rating]
    #from(CercleApi.TimelineEvent], order_by: [desc: :inserted_at])

		stage0 = Repo.all(query0)   |> Repo.preload([:user, {:main_contact, activities: (from a in CercleApi.Activity, where: a.is_done == false) }, {:main_contact, timeline_event: from(CercleApi.TimelineEvent, order_by: [desc: :inserted_at])}])
    stage1 = Repo.all(query1)   |> Repo.preload([:user, {:main_contact, activities: (from a in CercleApi.Activity, where: a.is_done == false)}, {:main_contact, timeline_event: from(CercleApi.TimelineEvent, order_by: [desc: :inserted_at])}])
    stage2 = Repo.all(query2)   |> Repo.preload([:user, {:main_contact, activities: (from a in CercleApi.Activity, where: a.is_done == false)}, {:main_contact, timeline_event: from(CercleApi.TimelineEvent, order_by: [desc: :inserted_at])}])
    stage3 = Repo.all(query3)   |> Repo.preload([:user, {:main_contact, activities: (from a in CercleApi.Activity, where: a.is_done == false)}, {:main_contact, timeline_event: from(CercleApi.TimelineEvent, order_by: [desc: :inserted_at])}])
    stage4 = Repo.all(query4)   |> Repo.preload([:user, {:main_contact, activities: (from a in CercleApi.Activity, where: a.is_done == false)}, {:main_contact, timeline_event: from(CercleApi.TimelineEvent, order_by: [desc: :inserted_at])}])


		conn
		|> put_layout("adminlte.html")
		|> render "index.html",  company: company, stage0: stage0, stage1: stage1, stage2: stage2, stage3: stage3, stage4: stage4
  end

  def new(conn, _params) do

    company_id = conn.assigns[:current_user].company_id
    company = Repo.get!(CercleApi.Company, company_id) |> Repo.preload [:users]

    conn
    |> put_layout("app2.html")
    |> render "new.html", company: company
  end

  def edit(conn, %{"id" => id}) do
    company_id = conn.assigns[:current_user].company_id
    reward = Repo.get!(Contact, id) |> Repo.preload [:organization, :company]
    company = Repo.get!(CercleApi.Company, reward.company_id) |> Repo.preload [:users]

    query = from p in Organization,
      order_by: [desc: p.inserted_at]
    organizations = Repo.all(query)

    query = from reward_status_history in CercleApi.TimelineEvent,
      where: reward_status_history.contact_id == ^reward.id,
      order_by: [desc: reward_status_history.inserted_at]
    reward_status_history = Repo.all(query) |> Repo.preload [:user]

    changeset = Contact.changeset(reward)
		conn
		|> put_layout("adminlte.html")
		|> render "edit.html", reward: reward, changeset: changeset, company: company, reward_status_history: reward_status_history, organizations: organizations
  end



  def update(conn, %{"id" => id, "reward" => reward_params, "comment" => comment}) do
  end

end
