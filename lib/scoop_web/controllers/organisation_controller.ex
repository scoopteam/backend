defmodule ScoopWeb.OrganisationController do
  use ScoopWeb, :controller

  alias Scoop.{Organisation, Repo}

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    json conn, %{
      "status" => "okay",
      "message" => "Hello!"
    }
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, params) do
    params = Map.put(params, "owner_id", conn.assigns.current_user.id)

    changeset = Organisation.changeset(%Organisation{}, params)

    case Repo.insert(changeset) do
      {:ok, _} ->
        json(conn, %{status: "okay", data: %{code: changeset.changes.code}})
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{status: "error", errors: Scoop.Utils.changeset_error_to_string(changeset)})
    end
  end
end
