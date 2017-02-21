defmodule CercleApi.Router do
  use CercleApi.Web, :router
  use Passport

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
    plug :current_user
    plug :put_user_token
  end

  defp put_user_token(conn, _) do
    if current_user = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(conn, "user socket", current_user.id)
      assign(conn, :user_token, token)
    else
      conn
    end
  end

  pipeline :basic_auth do
    plug BasicAuth, use_config: {:cercleApi, :basic_auth}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end
	
  scope "/", CercleApi do
    pipe_through :browser # Use the default browser stack

    get "/login", SessionController, :new
    post "/login", SessionController, :create
    get "/logout", SessionController, :delete
    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create

    get "/forget-password", PasswordController, :forget_password
    post "/reset-password", PasswordController, :reset_password
    get "/password/reset/:password_reset_code/confirm", PasswordController, :confirm
    post "/password/reset/:password_reset_code/confirm", PasswordController, :confirm_submit

    get "/", PageController, :index   

    get "/settings/profile_edit", SettingsController, :profile_edit
    put "/settings/profile_update", SettingsController, :profile_update
    get "/settings/company_edit", SettingsController, :company_edit
    put "/settings/company_update", SettingsController, :company_update
    get "/settings/team_edit", SettingsController, :team_edit
    put "/settings/team_update", SettingsController, :team_update
    get "/settings/fields_edit", SettingsController, :fields_edit
    put "/settings/fields_update", SettingsController, :fields_update
    
    get "/organizations", OrganizationsController, :index
    get "/organizations/:id", OrganizationsController, :edit

    get "/contacts", ContactsController, :index
	  get "/contacts/new", ContactsController, :new
    get "/contacts/:id", ContactsController, :edit
	  put "/contacts/:id/update", ContactsController, :update

    get "/opportunity", OpportunityController, :index
    get "/activity", ActivityController, :index

    get "/statistics", ContactsController, :statistics

    get "/redirect_app", PageController, :redirect_app 

  end
		
  scope "/", CercleApi do
    pipe_through :api

    

    get "/api/v2/timeline_events", APIV2.TimelineEventController, :index
    post "/api/v2/timeline_events", APIV2.TimelineEventController, :create
    
    post "/api/v2/register", APIV2.UserController, :create
    post "/api/v2/login", APIV2.SessionController, :create

    resources "/api/v2/contact", APIV2.ContactController
    put "/api/v2/contact/:id/update_tags", APIV2.ContactController, :update_tags

    resources "/api/v2/companies", APIV2.CompanyController
    resources "/api/v2/organizations", APIV2.OrganizationController
    resources "/api/v2/opportunity", APIV2.OpportunityController
    resources "/api/v2/activity", APIV2.ActivityController
    
    post "/api/v2/webhook", APIV2.WebhookController, :create

  end

	scope "/admin" , CercleApi.Admin,  as: :admin do
    pipe_through :browser # Use the default browser stack
    pipe_through :basic_auth

    resources "/users", UserController
    resources "/companies", CompanyController
    #resources "/company_services", CompanyServiceController
	end
end
