defmodule CercleApi.Router do
  use CercleApi.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :basic_auth do
    plug BasicAuth, use_config: {:cercleApi, :basic_auth}
  end

  pipeline :browser_json do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :api_auth do
    plug ExOauth2Provider.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
    plug CercleApi.Plug.CurrentCompany
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser_auth do
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  pipeline :require_login do
    plug Guardian.Plug.EnsureAuthenticated, handler: CercleApi.GuardianErrorHandler
    plug CercleApi.Plug.CurrentUser
    plug CercleApi.Plug.CurrentCompany
  end

  pipeline :already_authenticated do
    plug Guardian.Plug.EnsureNotAuthenticated, handler: CercleApi.GuardianAlreadyAuthenticatedHandler
  end

  scope "/", CercleApi do
    pipe_through [:browser, :browser_auth]
    get "/register/:register_values/join/", RegistrationController, :accept_team_invitation
    get "/register/:register_values/join/:useless_gmail", RegistrationController, :accept_team_invitation
  end

  scope "/", CercleApi do
    pipe_through [:browser, :browser_auth, :already_authenticated]
    get "/", PageController, :index
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create

    get "/forget-password", PasswordController, :forget_password
    post "/reset-password", PasswordController, :reset_password
    get "/password/reset/:password_reset_code/confirm", PasswordController, :confirm
    post "/password/reset/:password_reset_code/confirm", PasswordController, :confirm_submit
  end

  scope "/", CercleApi do
    pipe_through [:browser, :browser_auth, :require_login]

    get "/logout", SessionController, :delete

  end

  scope "/company/:company_id", CercleApi, as: :front do
    pipe_through [:browser, :browser_auth, :require_login]
    resources "/board", BoardController do
      resources "/card", CardController, only: [:show]
    end
    get "/contact", ContactController, :index
    get "/contact/new", ContactController, :new
    get "/contact/:id", ContactController, :show
    get "/contact/:id/card/:card_id", ContactController, :show

    get "/activity", ActivityController, :index

    get "/import", ImportController, :import
    post "/import_data", ImportController, :import_data
    post "/view_uploaded_data", ImportController, :view_uploaded_data
    post "/create_nested_data", ImportController, :create_nested_data

    get "/settings/profile", Settings.ProfileController, :edit, as: :edit_profile

    scope "/settings", Settings, as: :settings do
      resources "/companies", CompanyController
    end
    get "/settings/team_edit", SettingsController, :team_edit
    delete "/settings/remove_team_member/:user_id", SettingsController, :remove_team_member
    put "/settings/team_update", SettingsController, :team_update
    get "/settings/fields_edit", SettingsController, :fields_edit
    put "/settings/fields_update", SettingsController, :fields_update
    post "/settings/team_invitation", SettingsController, :team_invitation
    get "/settings/tags_edit", SettingsController, :tags_edit
    get "/settings/api_key", SettingsController, :api_key

  end

  scope "/api/v2", CercleApi.APIV2 do
    pipe_through [:api, :api_auth]

    post "/register", UserController, :create
    post "/login", SessionController, :create
    resources "/companies", CompanyController

    resources "/profile", UserProfileController, only: [:show, :update], singleton: true
  end

  scope "/api/v2/company/:company_id", CercleApi.APIV2 do
    pipe_through [:api, :api_auth]
    resources "/contact", ContactController

    get "/company/users", CompanyController, :users
    post "/contact/export", ContactExportController, :export
    put "/contact/:id/update_tags", ContactController, :update_tags
    put "/contact/:id/utags", ContactController, :utags
    delete "/contact/multiple/delete", ContactController, :multiple_delete

    resources "/organizations", OrganizationController
    put "/card/reassign", CardController, :reassign, as: :reassign
    resources "/card", CardController do
      resources "/attachments", CardAttachmentController,
        only: [:index, :create, :delete]
    end
    resources "/tag", TagController, only: [:index, :create, :update, :delete]

    resources "/activity", ActivityController
    resources "/board", BoardController do
      put "/archive", BoardController, :archive, as: :archive
      put "/unarchive", BoardController, :unarchive, as: :unarchive
      put "/reorder_columns", BoardController, :reorder_columns
    end
    resources "/board_column", BoardColumnController do
      put "/reorder_cards", BoardColumnController, :reorder_cards
    end
    post "/bulk_contact_create", BulkController, :bulk_contact_create
    post "/bulk_tag_or_untag_contacts", BulkController, :bulk_tag_or_untag_contacts
    get "/user", UserController, :index
    resources "/timeline_events", TimelineEventController

    resources "/email", EmailController
  end

  scope "/admin" , CercleApi.Admin, as: :admin do
    pipe_through :browser # Use the default browser stack
    pipe_through :basic_auth

    resources "/users", UserController
    resources "/companies", CompanyController
    resources "/oauth_application", OauthApplicationController, except: [:show]
    #resources "/company_services", CompanyServiceController
  end

  scope "/oauth", as: "oauth" do
    post "/token", CercleApi.Oauth.TokenController, :create
    post "/revoke", CercleApi.Oauth.TokenController, :revoke
    post "/refresh", CercleApi.Oauth.TokenController, :create
  end

  scope "/oauth", as: "oauth" do
    pipe_through [:browser, :browser_auth, :require_login]
    scope "/authorize" do
      get "/", CercleApi.Oauth.AuthorizationController, :new
      post "/", CercleApi.Oauth.AuthorizationController, :create
      get "/:code", CercleApi.Oauth.AuthorizationController, :show
      delete "/", CercleApi.Oauth.AuthorizationController, :delete
    end
  end

end
