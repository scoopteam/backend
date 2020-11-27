defmodule ScoopWeb.GroupController do
  use ScoopWeb, :controller

  alias Scoop.{Repo, OrganisationMembership, Permissions, Group, GroupMembership, User}

  @doc """
  Create a new group using the provided parameters.
  """
  @spec create(Plug.Conn.t(), nil | maybe_improper_list | map) :: Plug.Conn.t()
  def create(conn, params) do
    org_id = params["organisation_id"]

    # Search for a membership of the organisation from the user
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      # If the membership is nil, they are not a member
      nil ->
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})

      om ->
        # Check if the user has owner or admin privileges
        if Permissions.has_any_perm?(om.permissions, ["owner", "admin"]) do
          # Construct a change set with the provided parameters
          changeset = Group.changeset(%Group{}, params)

          # Try to insesrt the group
          case Repo.insert(changeset) do
            {:ok, obj} ->
              # Success, return the new details
              json(conn, %{status: "okay", data: %{id: obj.id}})

            {:error, cs} ->
              # Failure, return the erroring fields
              conn
              |> put_status(400)
              |> json(%{status: "error", errors: Scoop.Utils.changeset_error_to_string(cs)})
          end
        else
          # User is not authorized to create groups
          conn
          |> put_status(403)
          |> json(%{status: "error", message: "You do not have permission to create groups"})
        end
    end
  end

  @doc """
  Add the logged in user to a group
  """
  def update(conn, %{"organisation_id" => org_id, "id" => group_id}) do
    # Check the user is a member of the organisation
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        # User is not a member
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})

      om ->
        # Check if the group exists
        case Repo.get_by(Group, organisation_id: org_id, id: group_id) do
          nil ->
            conn
            |> put_status(404)
            |> json(%{status: "error", message: "Group does not exist"})

          group ->
            # Check if the user is already a member
            case Repo.get_by(
                   GroupMembership,
                   organisation_membership_id: om.id,
                   group_id: group_id,
                   user_id: conn.assigns.current_user.id
                 ) do
              nil ->
                # Check if the group is public or the user is an admin
                if group.public or Permissions.has_any_perm?(om.permissions, ["admin", "owner"]) do
                  # Create a new group membership with the organisation member and the group
                  GroupMembership.changeset(%GroupMembership{}, %{
                    organisation_membership_id: om.id,
                    group_id: group_id,
                    user_id: conn.assigns.current_user.id
                  })
                  |> Repo.insert()

                  json(conn, %{status: "okay"})
                else
                  # Group is invite-only
                  conn
                  |> put_status(403)
                  |> json(%{status: "error", message: "Invite-only group"})
                end
            end
        end
    end
  end

  @doc """
  Bulk add users to a group by email
  """
  def bulk_add(conn, %{"org_id" => org_id, "group_id" => group_id, "users" => users}) do
    # Check if the user is an organisation member
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})

      om ->
        # Check if the user has permission to bulk add
        if Permissions.has_any_perm?(om.permissions, ["owner", "admin"]) do
          # Construct a list of added and failed users
          {added, failed} =
            Enum.reduce(users, {[], []}, fn user, {added, failed} ->
              # Try fetch the user
              case Repo.get_by(User, email: user) do
                nil ->
                  # User does not exist, add the email to failed
                  {added, failed ++ [user]}

                usr ->
                  # Check the user is a member of the organisation
                  case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: usr.id) do
                    nil ->
                      # If the user is not a member, fail them
                      {added, failed ++ [user]}

                    org_membership ->
                      # Create a new group membership
                      cs =
                        GroupMembership.changeset(%GroupMembership{}, %{
                          organisation_membership_id: org_membership.id,
                          group_id: group_id,
                          user_id: usr.id
                        })

                      # Insert the new group membership
                      case Repo.insert(cs) do
                        # If the user succeeded add them to the added list
                        {:ok, _} ->
                          {added ++ [user], failed}

                        # If there was an error do more processing
                        {:error, cs} ->
                          # User is already a member
                          if elem(cs.errors[:group_id], 0) == "is already a member" do
                            {added ++ [user], failed}
                          else
                            # An error which was not an existing membership occurred.
                            {added, failed ++ [user]}
                          end
                      end
                  end
              end
            end)

          # Return details with the users that were added and failed to add
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

  @doc """
  Leave or delete a group.
  """
  def delete(conn, %{"organisation_id" => org_id, "id" => group_id, "delete" => should_delete?}) do
    # Check the user is a member
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})

      om ->
        # If delete is true and the user is an admin delete the group, else leave it
        if should_delete? and Permissions.has_any_perm?(om.permissions, ["admin", "owner"]) do
          group = Repo.get_by(Group, id: group_id, organisation_id: org_id)

          if group do
            # Delete the group
            Repo.delete(group)
            json(conn, %{status: "okay"})
          else
            conn
            |> put_status(404)
            |> json(%{status: "Group not found (tried delete)"})
          end
        else
          # Fetch the users group membership
          gm =
            Repo.get_by(GroupMembership,
              organisation_membership_id: om.id,
              group_id: group_id,
              user_id: conn.assigns.current_user.id
            )

          # If membership found, delete it
          if gm do
            Repo.delete(gm)
            json(conn, %{status: "okay"})
          else
            # User was not a member of the group
            conn
            |> put_status(404)
            |> json(%{status: "Group not found (tried leave)"})
          end
        end
    end
  end

  @doc """
  Shows the details on a group.
  """
  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"organisation_id" => org_id, "id" => group_id}) do
    # Check the user is an organisation member
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})

      om ->
        # Fetch the group
        case Repo.get_by(Group, organisation_id: org_id, id: group_id) do
          nil ->
            conn
            |> put_status(403)
            |> json(%{status: "error", message: "You do not have permission to access this group"})

          group ->
            # If user is an admin, return more info
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
              # User is not an admin, check if they are a mebmber
              case Repo.get_by(GroupMembership,
                     organisation_membership_id: om.id,
                     group_id: group_id,
                     user_id: conn.assigns.current_user.id
                   ) do
                nil ->
                  if not group.public do
                    # Private group
                    conn
                    |> put_status(403)
                    |> json(%{
                      status: "error",
                      message: "You do not have permission to access this group"
                    })
                  else
                    # Return info and a joined key set to false
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
                  # Return the information on the group to the user.
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

  @doc """
  Return a list of all groups in an organisation.
  """
  def index(conn, %{"organisation_id" => org_id}) do
    # Check the user is a member.
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{status: "error", message: "Organisation membership not found"})

      om ->
        # Check if the user has permission to view private groups
        view_private = Permissions.has_any_perm?(om.permissions, ["owner", "admin"])

        # Preload the information on the organisation and the groups
        om = om |> Repo.preload(:org)
        org = om.org |> Repo.preload(:groups)

        # Convert the user models into encodable maps
        data =
          Enum.map(org.groups, fn g ->
            Scoop.Utils.model_to_map(g, [:name, :public, :auto_subscribe, :id])
          end)

        # Filter the groups
        # If user cannot view private groups, filter
        filtered =
          if not view_private do
            Enum.filter(data, fn group ->
              # If the user is a member of the group, return it.
              # If the group is public, return it.
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
            # If user can view private groups, return the data as-is
            data
          end

        json(conn, %{status: "okay", data: filtered})
    end
  end
end
