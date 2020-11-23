defmodule ScoopWeb.UserController do
  use ScoopWeb, :controller

  alias Scoop.{Repo, User}

  def index(conn, _params) do
    case conn.assigns.signed_in? do
      false ->
        conn
        |> put_status(401)
        |> json(%{status: "error", message: "This endpoint requires authentication"})

      true ->
        conn
        |> json(%{
          status: "okay",
          data:
            Scoop.Utils.model_to_map(
              conn.assigns.current_user,
              [:email, :full_name, :id, :inserted_at, :updated_at]
            )
        })
    end
  end

  def create(conn, params) do
    changeset = User.changeset(%User{}, params)

    case Repo.insert(changeset) do
      {:ok, _} ->
        json(conn, %{status: "okay", data: %{token: changeset.changes.token}})

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{status: "error", errors: Scoop.Utils.changeset_error_to_string(changeset)})
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Repo.get_by(User, email: email) do
      nil ->
        conn
        |> put_status(401)
        |> json(%{status: "error", errors: %{email: ["does not exist"]}})

      user ->
        case Argon2.verify_pass(password, user.password) do
          true ->
            json(conn, %{status: "okay", data: %{token: user.token}})

          false ->
            conn
            |> put_status(401)
            |> json(%{status: "error", errors: %{password: ["is incorrect"]}})
        end
    end
  end

  def show(conn, %{"id" => user_id}) do
    user = Repo.get(User, user_id)

    case user do
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{detail: "User not found"}})

      user ->
        json(conn, Scoop.Utils.model_to_map(user, [:email, :full_name]))
    end
  end
end
