defmodule ScoopWeb.OrganisationController do
  use ScoopWeb, :controller

  import Ecto.Query

  alias Scoop.{Organisation, Repo, OrganisationMembership, Permissions, Group, GroupMembership}

  @doc """
  Return a list of organisations the user is a member of.
  """
  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    # Query the memberships where the user ID is the current logged in user.
    memberships_query =
      from membership in OrganisationMembership,
        select: membership,
        where: membership.user_id == ^conn.assigns.current_user.id

    # Preload the organisation object
    all = Repo.all(memberships_query) |> Repo.preload(:org)

    data =
      Enum.map(all, fn x ->
        # Build a map to return
        data =
          %{}
          |> Map.put(:org, Scoop.Utils.model_to_map(x.org, [:name, :id]))
          |> Map.put(:permissions, x.permissions)

        if Permissions.has_any_perm?(x.permissions, ["admin", "owner"]) do
          # If the user is an admin, return a join code to display.
          Map.update(data, :org, %{}, fn org -> Map.put(org, :code, x.org.code) end)
        else
          data
        end
      end)

    json(conn, %{status: "okay", data: data})
  end

  @doc """
  Show the provided organisation
  """
  def show(conn, %{"id" => id}) do
    # If the user is a member of the organisation, return the data
    case Repo.get_by(OrganisationMembership, org_id: id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(403)
        |> json(%{status: "error", message: "Membership not found"})

      om ->
        # Preload the org object
        om = Repo.preload(om, :org)

        # Create the object to return
        data =
          %{}
          |> Map.put(:org, Scoop.Utils.model_to_map(om.org, [:name, :id]))
          |> Map.put(:permissions, om.permissions)

        data =
          # If the user is an admin, return details on the number of members and the code
          if Permissions.has_any_perm?(om.permissions, ["admin", "owner"]) do
            memberships = om.org |> Repo.preload(:memberships) |> Map.get(:memberships) |> length

            data
            |> Map.update(:org, %{}, fn org -> Map.put(org, :code, om.org.code) end)
            |> Map.update(:org, %{}, fn org -> Map.put(org, :member_count, memberships) end)
          else
            data
          end

        json(conn, %{status: "okay", data: data})
    end
  end

  @doc """
  Join the organisation with provided code
  """
  def join(conn, %{"code" => code}) do
    # Fetch the organisation from the code provided.
    case Repo.get_by(Organisation, code: code) do
      nil ->
        # If the code is not found, return a 404.
        conn
        |> put_status(404)
        |> json(%{status: "error", errors: %{"code" => ["not found"]}})

      org ->
        # Create a new organisation membership object.
        om =
          OrganisationMembership.changeset(%OrganisationMembership{}, %{
            user_id: conn.assigns.current_user.id,
            org_id: org.id,
            permissions: []
          })

        # Inser the organisation membership.
        case Repo.insert(om) do
          {:ok, new_om} ->
            # Start processing the groups that should be automatically joined.
            to_join_query = from group in Group,
              select: group,
              # Fetch the groups that have auto_subscribe enabled in the current organisation
              where: group.auto_subscribe == true and group.organisation_id == ^org.id

            to_join = Repo.all(to_join_query)

            # Create changesets to add the group memberships into the database.
            Enum.map(to_join, fn to_join_group ->
              GroupMembership.changeset(%GroupMembership{}, %{
                organisation_membership_id: new_om.id,
                group_id: to_join_group.id,
                user_id: conn.assigns.current_user.id
              })
              |> Repo.insert()
            end)

            json(conn, %{status: "okay"})

          {:error, cs} ->
            # Return errors to the user (i.e. already a member)
            conn
            |> put_status(400)
            |> json(%{status: "error", errors: Scoop.Utils.changeset_error_to_string(cs)})
        end
    end
  end

  @doc """
  Create a new organisation.
  """
  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, params) do
    # Add a new owner_id property.
    params = Map.put(params, "owner_id", conn.assigns.current_user.id)

    # Create a changeset from the parameters
    changeset = Organisation.changeset(%Organisation{}, params)

    case Repo.insert(changeset) do
      # If the add was successful, add a new membership to the organisation for the new user.
      {:ok, new_org} ->
        {:ok, _} =
          OrganisationMembership.changeset(%OrganisationMembership{}, %{
            user_id: conn.assigns.current_user.id,
            org_id: new_org.id,
            permissions: ["owner"]
          })
          |> Repo.insert()

        json(conn, %{status: "okay", data: %{id: new_org.id}})

      {:error, changeset} ->
        # Return input errors to the creator.
        conn
        |> put_status(400)
        |> json(%{status: "error", errors: Scoop.Utils.changeset_error_to_string(changeset)})
    end
  end

  @doc """
  Delete or leave the organisation.

  By default, any owner will just delete the organisation, any member will leave.
  """
  def delete(conn, %{"id" => id}) do
    # Check the user is a member
    case Repo.get_by(OrganisationMembership, org_id: id, user_id: conn.assigns.current_user.id) do
      # User is not a member
      nil ->
        conn
        |> put_status(403)
        |> json(%{status: "error", message: "Membership not found"})

      om ->
        # If the user is an owner
        if Permissions.has_perm?(om.permissions, "owner") do
          # Preload the organisation
          om = Repo.preload(om, :org)
          # Delete the organisation
          Repo.delete(om.org)
        else
          # Delete the membership
          Repo.delete(om)
        end

        json(conn, %{status: "okay"})
    end
  end
end
