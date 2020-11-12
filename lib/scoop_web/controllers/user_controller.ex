defmodule ScoopWeb.UserController do
  use ScoopWeb, :controller

  alias Scoop.{Repo, User}

  def index(conn, _params) do
    json conn, %{
      "status" => "okay",
      "message" => "Index for the user controller"
    }
  end

  def create(conn, params) do
    changeset = User.changeset(%User{}, params)

    case Repo.insert(changeset) do
      {:ok, _} -> json conn, %{status: "okay", token: changeset.changes.token}
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{errors: Scoop.Utils.changeset_error_to_string(changeset)})
    end
  end

  def show(conn, %{"id" => user_id}) do
    user = Repo.get(User, user_id)

    case user do
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{detail: "User not found"}})
      user -> json conn, Scoop.Utils.model_to_map(user, [:email, :full_name])
    end
  end
end
