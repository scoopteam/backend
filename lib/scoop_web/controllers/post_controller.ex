defmodule ScoopWeb.PostController do
  use ScoopWeb, :controller

  alias Scoop.{GroupMembership, Post, Repo, OrganisationMembership, Permissions}

  def index(conn, %{"group_id" => group_id}) do
    case Repo.get_by(GroupMembership, group_id: group_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(403)
        |> json(%{status: "error", message: "Not a group member"})
      membership ->
        membership = membership |> Repo.preload(group: [posts: [:author]])

        data = Enum.map(membership.group.posts, fn post ->
          Scoop.Utils.model_to_map(post, [:id, :title, :content])
          |> Map.put(:author, Scoop.Utils.model_to_map(post.author, [:full_name]))
        end)

        json conn, %{status: "okay", data: data}
    end
  end

  def create(conn, params) do
    org_id = params["organisation_id"]
    case Repo.get_by(OrganisationMembership, org_id: org_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(403)
        |> json(%{status: "error", message: "Not a group member"})
      membership ->
        if Permissions.has_any_perm?(membership.permissions, ["admin", "owner"]) do
          params = params |> Map.merge(%{"author_id" => conn.assigns.current_user.id})
          cs = Post.changeset(%Post{}, params)

          case Repo.insert(cs) do
            {:ok, _} -> json(conn, %{status: "okay"})
            {:error, cs} ->
              conn
              |> put_status(400)
              |> json(%{status: "error", errors: Scoop.Utils.changeset_error_to_string(cs)})
          end
        end
    end
  end
end
