defmodule ScoopWeb.PostController do
  use ScoopWeb, :controller

  alias Scoop.{GroupMembership, Post, Repo, OrganisationMembership, Permissions}

  @doc """
  Return a list of posts in the current group.
  """
  def index(conn, %{"group_id" => group_id}) do
    # Check the user is a group member
    case Repo.get_by(GroupMembership, group_id: group_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(403)
        |> json(%{status: "error", message: "Not a group member"})
      membership ->
        # Preload the posts with the auhtor object
        membership = membership |> Repo.preload(group: [posts: [:author]])

        # Create a map to return with the post and author name
        data = Enum.map(membership.group.posts, fn post ->
          Scoop.Utils.model_to_map(post, [:id, :title, :content])
          |> Map.put(:author, Scoop.Utils.model_to_map(post.author, [:full_name]))
        end)

        # Return the list of posts
        json conn, %{status: "okay", data: data}
    end
  end

  @doc """
  Create a new post in a group.
  """
  def create(conn, params) do
    org_id = params["organisation_id"]
    # Check the user is in the organisation
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(403)
        |> json(%{status: "error", message: "Not a group member"})
      membership ->
        # Check the user has admin or owner permissions
        if Permissions.has_any_perm?(membership.permissions, ["admin", "owner"]) do
          # Add the author_id property
          params = params |> Map.merge(%{"author_id" => conn.assigns.current_user.id})

          # Create a changeset with provided parameters
          cs = Post.changeset(%Post{}, params)

          # Insert the new post
          case Repo.insert(cs) do
            {:ok, _} -> json(conn, %{status: "okay"})
            {:error, cs} ->
              # Return the erroring fields
              conn
              |> put_status(400)
              |> json(%{status: "error", errors: Scoop.Utils.changeset_error_to_string(cs)})
          end
        end
    end
  end
end
