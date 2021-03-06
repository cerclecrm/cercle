defmodule CercleApi.User do
  @moduledoc """
  User are the people who use Cercle CRM.
  Each User belongs to a company.
  """

  use CercleApi.Web, :model
  use Arc.Ecto.Schema
  alias CercleApi.{Repo, UserCompany}
  @derive {Poison.Encoder, only: [
              :id, :full_name, :profile_image
            ]}

  schema "users" do
    field :full_name, :string #is full rname
    field :password, :string, virtual: true
    field :password_hash, :string
    field :password_reset_code, :string
    field :notification, :boolean
    field :login, :string
    field :profile_image, CercleApi.UserProfileImage.Type
    field :username, :string #is username
    field :time_zone, :string, default: "America/New_York"
    timestamps

    has_many :user_companies, CercleApi.UserCompany
    has_many :companies, through: [:user_companies, :company]

    has_many :activities, CercleApi.Activity, on_delete: :delete_all
    has_many :timeline_event, CercleApi.TimelineEvent
    has_many :cards, CercleApi.Card

    has_many :tokens, ExOauth2Provider.OauthAccessTokens.OauthAccessToken, foreign_key: :resource_owner_id
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :invalid) do
    model
    |> cast(params, [
          :login, :full_name, :password_reset_code,
          :username, :time_zone, :notification])
    |> cast_attachments(params, [:profile_image])
    |> validate_required([:login])
    |> unique_constraint(:login)

  end

  def registration_changeset(model, params) do
    model
    |> changeset(params)
    |> cast(params, [:password])
    |> validate_length(:password, min: 6, max: 100)
    |> generate_encrypted_password()
    |> generate_username()
    |> validate_required([:username])
    |> unique_constraint(:username)
  end

  def update_changeset(model, params) do
    if params["password"] != "" do
      model
      |> changeset(params)
      |> cast(params, [:password])
      |> validate_length(:password, min: 6, max: 100)
      |> generate_encrypted_password()
    else
      model
      |> changeset(params)
      |> validate_required([:username])
      |> unique_constraint(:username)
    end
  end

  def update_user_name(model) do
    model
    |> changeset(%{})
    |> generate_username()
    |> validate_required([:username])
    |> unique_constraint(:username)
  end

  def company_users(company) do
    Repo.all(
      from c in __MODULE__,
      join: p in assoc(c, :companies),
      where: p.id == ^company.id
    )
  end

  defp generate_encrypted_password(current_changeset) do
    case current_changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(current_changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))
      _ ->
        current_changeset
    end
  end

  defp generate_username(changeset) do
    case String.trim(to_string(get_field(changeset, :username))) do
      "" -> put_change(changeset, :username, generate_uniq_username)
      _ -> changeset
    end
  end

  defp generate_uniq_username do
    with username <- "user-#{Base.encode16(:crypto.strong_rand_bytes(3))}",
         true <- is_nil(Repo.get_by(__MODULE__, username: username)) do
      username
    else
      _ -> generate_uniq_username
    end
  end
end



defimpl Poison.Encoder, for: CercleApi.User do
  def encode(model, options) do
    model
    |> Map.take([:id, :full_name, :username, :profile_image])
    |> Map.put(:profile_image_url, CercleApi.UserProfileImage.url({model.profile_image, model}, :small))
    |> Poison.Encoder.encode(options)
  end
end
