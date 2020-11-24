defmodule ScoopWeb.OrganisationController do
  use ScoopWeb, :controller

  import Ecto.Query

  alias Scoop.{Organisation, Repo, OrganisationMembership, Permissions}

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    memberships_query = from membership in OrganisationMembership,
      select: membership,
      where: membership.user_id == ^conn.assigns.current_user.id

    all = Repo.all(memberships_query) |> Repo.preload(:org)

    data = Enum.map(all, fn x ->
      data = %{}
      |> Map.put(:org, Scoop.Utils.model_to_map(x.org, [:name, :id]))
      |> Map.put(:permissions, x.permissions)

      if Permissions.has_any_perm?(x.permissions, ["admin", "owner"]) do
        Map.update(data, :org, %{}, fn org -> Map.put(org, :code, x.org.code) end)
      else
        data
      end
    end)

    json conn, %{status: "okay", data: data}
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, params) do
    params = Map.put(params, "owner_id", conn.assigns.current_user.id)

    changeset = Organisation.changeset(%Organisation{}, params)

    case Repo.insert(changeset) do
      {:ok, new_org} ->
        {:ok, _} = OrganisationMembership.changeset(%OrganisationMembership{}, %{
          user_id: conn.assigns.current_user.id,
          org_id: new_org.id,
          permissions: ["owner"]
        }) |> Repo.insert()

        json(conn, %{status: "okay", data: %{id: new_org.id}})
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{status: "error", errors: Scoop.Utils.changeset_error_to_string(changeset)})
    end
  end
end
