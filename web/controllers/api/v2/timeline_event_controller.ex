defmodule CercleApi.APIV2.TimelineEventController do
  use CercleApi.Web, :controller
  alias CercleApi.{TimelineEvent, User, Contact, Repo}

  plug Guardian.Plug.EnsureAuthenticated
  plug :scrub_params, "timeline_event" when action in [:create]

  def index(conn, _params) do
    te = Repo.all(TimelineEvent)
    render(conn, "index.json", timeline_events: te)
  end

  def create(conn, %{"timeline_event" => timeline_event_params}) do
    current_user = Guardian.Plug.current_resource(conn)

    changeset = current_user
    |> build_assoc(:timeline_event)
    |> TimelineEvent.changeset(timeline_event_params)

    case Repo.insert(changeset) do
      {:ok, timeline_event} ->

        timeline_event_reload = Repo.get!(CercleApi.TimelineEvent, timeline_event.id) |> Repo.preload [:user]
        html = Phoenix.View.render_to_string(CercleApi.ContactView, "_timeline_event.html", timeline_event: timeline_event_reload)
        channel = "contacts:"  <> to_string(timeline_event_reload.contact_id)
        CercleApi.Endpoint.broadcast!(channel, "new:timeline_event", %{"html" => html})
        CercleApi.Endpoint.broadcast!(
          "contacts:"  <> to_string(timeline_event_reload.contact_id),
          "timeline_event:created", %{"event" => timeline_event_reload}
        )

        ### THE CODE BELOW IS USELESS, WE NEED TO GET THE IDs OF THE USER WILL NOTIFIY INSTEAD OF PARSING THE CONTENT OF THE TEXTAREA
        user = current_user
        contact = Repo.get!(CercleApi.Contact, timeline_event_params["contact_id"]) |> Repo.preload [:company]
      	comment = timeline_event_params["content"]
      	company = contact.company
      	parts = String.split(comment, " ")

        users = company
        |> assoc(:users)
        |> Repo.all

        Enum.each parts, fn x ->
          Enum.each users, fn u ->
            if x == ("@" <> to_string(u.name)) do
              CercleApi.Mailer.deliver notification_email(u.login, contact, true, comment, company, user , u)
            end
          end
        end

        conn
        |> put_status(:created)
        |> render("show.json", timeline_event: timeline_event)


      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CercleApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def notification_email(emailTo, reward, status, comment, company, user, user2) do
      %Mailman.Email{
        subject: user.user_name <> " commented on " <> reward.name,
        from: "referral@cercle.co",
        to: [emailTo],
        html: Phoenix.View.render_to_string(CercleApi.EmailView, "lead_notification.html", reward: reward, status: status, comment: comment, company: company, user: user, user2: user2)
        }
  end

end
