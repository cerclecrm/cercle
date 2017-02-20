defmodule CercleApi.Session do
  alias CercleApi.{Repo, User}

  def authenticate(login, password) do
    user = Repo.get_by(User, login: String.downcase(login))
    case check_password(user, password) do
      true -> {:ok, user}
      _ -> :error
    end
  end

  defp check_password(user, password) do
    case user do
      nil -> Comeonin.Bcrypt.dummy_checkpw()
      _ -> Comeonin.Bcrypt.checkpw(password, user.password_hash)
    end
  end
end
