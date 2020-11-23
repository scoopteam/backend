defmodule ScoopWeb.Plugs.SetCurrentUser do
  import Phoenix.Controller, only: [json: 2]

  import Plug.Conn

  alias Scoop.{Repo, User}

  @spec init(any) :: any
  def init(opts \\ %{auth_required: false}) do
    opts
  end

  @spec handle_nil_user(Plug.Conn.t(), any) :: Plug.Conn.t()
  def handle_nil_user(conn, auth_required) do
    case auth_required do
      true ->
        conn
        |> put_status(401)
        |> json(%{status: "error", message: "This endpoint requires authorization"})
        |> halt()

      _ ->
        conn
        |> assign(:current_user, nil)
        |> assign(:signed_in?, false)
    end
  end

  @spec assign_logged_in_user(Plug.Conn.t(), any) :: Plug.Conn.t()
  def assign_logged_in_user(conn, user) do
    conn
    |> assign(:current_user, user)
    |> assign(:signed_in?, true)
  end

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, opts) do
    token = get_req_header(conn, "authorization")

    if token |> length > 0 do
      token = Enum.at(token, 0)

      user = Repo.get_by(User, token: token)

      case user do
        nil ->
          conn |> handle_nil_user(opts[:auth_required])

        user ->
          conn |> assign_logged_in_user(user)
      end
    else
      conn |> handle_nil_user(opts[:auth_required])
    end
  end
end
