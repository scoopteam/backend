defmodule ScoopWeb.PostController do
  use ScoopWeb, :controller

  alias Scoop.{GroupMembership, Repo}

  def index(conn, %{"group_id" => group_id}) do
    case Repo.get_by(GroupMembership, group_id: group_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(403)
        |> json(%{status: "error", message: "Not a group member"})
      membership ->
        membership = membership |> Repo.preload(group: [posts: [:author]])

        data = Enum.map(membership.group.posts, fn post ->
          Scoop.Utils.model_to_map(post, [:id, :title, :text])
          |> Map.put(:author, Scoop.Utils.model_to_map(post.author, [:full_name]))
        end)

        json conn, %{status: "okay", data: data}
    end
  end
end
