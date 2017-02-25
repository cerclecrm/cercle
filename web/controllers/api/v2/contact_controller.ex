defmodule CercleApi.APIV2.ContactController do
  require Logger
  use CercleApi.Web, :controller

  alias CercleApi.Contact
  alias CercleApi.Company
  alias CercleApi.Organization
  alias CercleApi.Opportunity
  alias CercleApi.User
  alias CercleApi.Activity
  alias CercleApi.Tag
  alias CercleApi.ContactTag

  plug :scrub_params, "contact" when action in [:create, :update]



  def index(conn, _params) do
    contacts = Repo.all(Contact)
    render(conn, "index.json", contacts: contacts)
  end

  def create(conn, %{"contact" => contact_params}) do
    company_id = contact_params["company_id"]
    if contact_params["email"] do 
      domain_email = List.first(Enum.take(String.split(contact_params["email"], "@"), -1))

      query = from organization in Organization,
        where: organization.website == ^domain_email,
        where: organization.company_id == ^company_id
  
      organizations = Repo.all(query)
  
      if Enum.count(organizations) == 0 do
        organization_params = %{"name" => domain_email, "website" => domain_email, "company_id" => company_id}
        changeset = Organization.changeset(%Organization{}, organization_params)
        case Repo.insert(changeset) do
          {:ok, org} ->
            organization_id = org.id
        end
      end
  
      organizations = Repo.all(query)
      organization = Enum.at(organizations, 0)
      organization_id = organization.id
      contact_params = %{contact_params | "organization_id" => organization_id}
    end

    changeset = Contact.changeset(%Contact{}, contact_params)
    case Repo.insert(changeset) do
      {:ok, contact} ->
        conn
        |> put_status(:created)
        |> render("show.json", contact: contact)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CercleApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"user_id" => user_id, "company_id" => company_id}) do
    
    query = from contact in Contact,
      where: contact.user_id == ^user_id and contact.company_id == ^company_id,
      order_by: [desc: contact.id]

    contacts = Repo.all(query)
    render(conn, "index.json", contacts: contacts)
  end

  def update(conn, %{"id" => id, "contact" => contact_params}) do
    contact = Repo.get!(Contact, id)
    if contact_params["data"] do
      new_data = Map.merge(contact.data , contact_params["data"])
      contact_params = %{contact_params | "data" => new_data}
    end
    changeset = Contact.changeset(contact, contact_params)

    case Repo.update(changeset) do
      {:ok, contact} ->
        channel = "contacts:"  <> to_string(contact.id)
        CercleApi.Endpoint.broadcast!( channel, "state", contact)
        render(conn, "show.json", contact: contact)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CercleApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update_tags(conn, %{"id" => id, "tags" => tag_params, "company_id" => company_id_string}) do
    contact = Repo.get!(Contact, id)
    {company_id, _rest} = Integer.parse(company_id_string)
    #tag_params
    query = from c in ContactTag,
        where: c.contact_id == ^id
      Repo.delete_all(query)
    
    if tag_params == "" do
      render(conn, "show.json", contact: contact)
    else
      tag_ids = Enum.map tag_params, fn tag ->
        #tag
        if Regex.run(~r/^[\d]+$/, tag) do 
          {tag_id, _rest} = Integer.parse(tag)
          tag_id
        else
          Repo.insert!(%Tag{name: tag, company_id: company_id}).id
        end
      end
      query = from tag in Tag,
        where: tag.id in ^tag_ids
      tags = Repo.all(query)
          changeset = contact
        |> Repo.preload(:tags) # Load existing data
        |> Ecto.Changeset.change() # Build the changeset
        |> Ecto.Changeset.put_assoc(:tags, tags) # Set the association
  
      case Repo.update(changeset) do
        {:ok, contact} ->
          render(conn, "show.json", contact: contact)
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(CercleApi.ChangesetView, "error.json", changeset: changeset)
      end
    end

  

  end

  def delete(conn, %{"id" => id}) do
    contact = Repo.get!(Contact, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(contact)

    send_resp(conn, :no_content, "")
  end
end
