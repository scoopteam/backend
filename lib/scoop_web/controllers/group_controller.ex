defmodule ScoopWeb.GroupController do
  use ScoopWeb, :controller

  alias Scoop.{Repo, OrganisationMembership, Permissions, Group, GroupMembership, User}

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

  def update(conn, %{"organisation_id" => org_id, "id" => group_id}) do
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})

      om ->
        case Repo.get_by(Group, organisation_id: org_id, id: group_id) do
          nil ->
            json(conn, %{status: "error", message: "Group does not exist"})

          group ->
            case Repo.get_by(
                   GroupMembership,
                   organisation_membership_id: om.id,
                   group_id: group_id,
                   user_id: conn.assigns.current_user.id
                 ) do
              nil ->
                if group.public or Permissions.has_any_perm?(om.permissions, ["admin", "owner"]) do
                  GroupMembership.changeset(%GroupMembership{}, %{
                    organisation_membership_id: om.id,
                    group_id: group_id,
                    user_id: conn.assigns.current_user.id
                  })
                  |> Repo.insert()

                  json(conn, %{status: "okay"})
                else
                  conn
                  |> put_status(403)
                  |> json(%{status: "error", message: "Invite-only group"})
                end
            end
        end
    end
  end

  def bulk_add(conn, %{"org_id" => org_id, "group_id" => group_id, "users" => users}) do
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})

      om ->
        if Permissions.has_any_perm?(om.permissions, ["owner", "admin"]) do
          {added, failed} =
            Enum.reduce(users, {[], []}, fn user, {added, failed} ->
              case Repo.get_by(User, email: user) do
                nil ->
                  {added, failed ++ [user]}

                usr ->
                  case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: usr.id) do
                    nil ->
                      {added, failed ++ [user]}

                    org_membership ->
                      cs =
                        GroupMembership.changeset(%GroupMembership{}, %{
                          organisation_membership_id: org_membership.id,
                          group_id: group_id,
                          user_id: usr.id
                        })

                      case Repo.insert(cs) do
                        {:ok, _} -> {added ++ [user], failed}
                        {:error, cs} ->
                          if elem(cs.errors[:group_id], 0) == "is already a member" do
                            {added ++ [user], failed}
                          else
                           {added, failed ++ [user]}
                          end
                      end
                  end
              end
            end)

          json(conn, %{
            status: "okay",
            data: %{
              added: added,
              failed: failed
            }
          })
        else
          conn
          |> put_status(403)
          |> json(%{status: "error", message: "No permission to bulk ingest"})
        end
    end
  end

  def delete(conn, %{"organisation_id" => org_id, "id" => group_id, "delete" => should_delete?}) do
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})

      om ->
        if should_delete? and Permissions.has_any_perm?(om.permissions, ["admin", "owner"]) do
          group = Repo.get_by(Group, id: group_id, organisation_id: org_id)

          if group do
            Repo.delete(group)
            json(conn, %{status: "okay"})
          else
            conn
            |> put_status(404)
            |> json(%{status: "Group not found (tried delete)"})
          end
        else
          gm =
            Repo.get_by(GroupMembership,
              organisation_membership_id: om.id,
              group_id: group_id,
              user_id: conn.assigns.current_user.id
            )

          if gm do
            Repo.delete(gm)
            json(conn, %{status: "okay"})
          else
            conn
            |> put_status(404)
            |> json(%{status: "Group not found (tried leave)"})
          end
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
              org_member? =
                Repo.get_by(GroupMembership,
                  organisation_membership_id: om.id,
                  group_id: group_id,
                  user_id: conn.assigns.current_user.id
                ) != nil

              json(conn, %{
                status: "okay",
                data:
                  Scoop.Utils.model_to_map(group, [
                    :name,
                    :public,
                    :auto_subscribe,
                    :id
                  ])
                  |> Map.merge(%{joined: org_member?})
              })
            else
              case Repo.get_by(GroupMembership,
                     organisation_membership_id: om.id,
                     group_id: group_id,
                     user_id: conn.assigns.current_user.id
                   ) do
                nil ->
                  if not group.public do
                    conn
                    |> put_status(403)
                    |> json(%{
                      status: "error",
                      message: "You do not have permission to access this group"
                    })
                  else
                    json(conn, %{
                      status: "okay",
                      data:
                        Scoop.Utils.model_to_map(group, [
                          :name,
                          :public,
                          :auto_subscribe,
                          :id
                        ])
                        |> Map.merge(%{joined: false})
                    })
                  end

                _ ->
                  json(conn, %{
                    status: "okay",
                    data:
                      Scoop.Utils.model_to_map(group, [
                        :name,
                        :public,
                        :auto_subscribe,
                        :id
                      ])
                  })
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

        data =
          Enum.map(org.groups, fn g ->
            Scoop.Utils.model_to_map(g, [:name, :public, :auto_subscribe, :id])
          end)

        filtered =
          if not view_private do
            Enum.filter(data, fn group ->
              case Repo.get_by(GroupMembership,
                     organisation_membership_id: om.id,
                     group_id: group.id,
                     user_id: conn.assigns.current_user.id
                   ) do
                nil -> group.public
                _membership -> true
              end
            end)
          else
            data
          end

        json(conn, %{status: "okay", data: filtered})
    end
  end
end
