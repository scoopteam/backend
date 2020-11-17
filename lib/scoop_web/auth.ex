defmodule ScoopWeb.Plugs.SetCurrentUser do
  import Plug.Conn

  alias Scoop.{Repo, User}

  def init(_params) do
  end

  def call(conn, _params) do
    token = get_req_header(conn, "authorization")

    token = if (token |> length) > 0 do
      token |> Enum.at(0)
    else
      nil
    end

    user = Repo.get_by(User, token: token)

    case user do
      nil ->
        assign(conn, :current_user, nil)
        assign(conn, :signed_in?, false)
      user ->
        assign(conn, :current_user, user)
        assign(conn, :signed_in?, true)
    end
  end
end
