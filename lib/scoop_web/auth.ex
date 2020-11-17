defmodule ScoopWeb.Plugs.SetCurrentUser do
  import Plug.Conn

  alias Scoop.{Repo, User}

  def init(_params) do
  end

  def assign_nil_user(conn) do
      assign(conn, :current_user, nil)
      assign(conn, :signed_in?, false)
  end

  def assign_logged_in_user(conn, user) do
    assign(conn, :current_user, user)
    assign(conn, :signed_in?, true)
  end

  def call(conn, _params) do
    token = get_req_header(conn, "authorization")

    if (token |> length) > 0 do
      token = Enum.at(0)

      user = Repo.get_by(User, token: token)

      case user do
        nil ->
          conn |> assign_nil_user
        user ->
          conn |> assign_logged_in_user(user)
      end
    else
      conn |> assign_nil_user
    end
  end
end
