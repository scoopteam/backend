defmodule ScoopWeb.GroupController do
  use ScoopWeb, :controller

  alias Scoop.{Repo, OrganisationMembership, Permissions, Group, GroupMembership}

  @spec create(Plug.Conn.t(), nil | maybe_improper_list | map) :: Plug.Conn.t()
  def create(conn, params) do
    org_id = params["organisation_id"]

    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})
      om ->
        if Permissions.has_any_perm?(om.permissions, ["owner", "admin"]) do
          changeset = Group.changeset(%Group{}, params)

          case Repo.insert(changeset) do
            {:ok, obj} ->
              json(conn, %{status: "okay", data: %{id: obj.id}})
            {:error, cs} ->
              conn
              |> put_status(400)
              |> json(%{status: "error", errors: Scoop.Utils.changeset_error_to_string(cs)})
          end
        else
          conn
          |> put_status(403)
          |> json(%{status: "error", message: "You do not have permission to create groups"})
        end
    end
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"organisation_id" => org_id, "id" => group_id}) do
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})
      om ->
        case Repo.get_by(Group, organisation_id: org_id, id: group_id) do
          nil ->
            conn
            |> put_status(403)
            |> json(%{status: "error", message: "You do not have permission to access this group"})

          group ->
            if Permissions.has_any_perm?(om.permissions, ["owner", "admin"]) do
              json conn, %{
                status: "okay",
                data: Scoop.Utils.model_to_map(group, [
                  :name,
                  :public,
                  :auto_subscribe,
                  :id
                ])
              }
            else
              case Repo.get_by(GroupMembership, organisation_membership_id: om.id, group_id: group_id, user_id: conn.assigns.current_user.id) do
                nil ->
                  conn
                  |> put_status(403)
                  |> json(%{status: "error", message: "You do not have permission to access this group"})
                _ ->
                  json conn, %{
                    status: "okay",
                    data: Scoop.Utils.model_to_map(group, [
                      :name,
                      :public,
                      :auto_subscribe,
                      :id
                    ])
                  }
              end
            end
          end
    end
  end

  def index(conn, %{"organisation_id" => org_id}) do
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})
      om ->
        view_private = Permissions.has_any_perm?(om.permissions, ["owner", "admin"])

        om = om |> Repo.preload(:org)
        org = om.org |> Repo.preload(:groups)

        data = Enum.map(org.groups, fn g ->
          Scoop.Utils.model_to_map(g, [:name, :public, :auto_subscribe, :id])
        end)

        filtered = if not view_private do
          Enum.filter(data, fn group ->
            group.public
          end)
        else
          data
        end

        json conn, %{status: "okay", data: filtered}
    end
  end
end
