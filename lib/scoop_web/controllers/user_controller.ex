defmodule ScoopWeb.UserController do
  use ScoopWeb, :controller

  alias Scoop.{Repo, User}

  @doc """
  Return the current logged in user.
  """
  def index(conn, _params) do
    case conn.assigns.signed_in? do
      false ->
        # User is not logged in
        conn
        |> put_status(401)
        |> json(%{status: "error", message: "This endpoint requires authentication"})

      true ->
        # Return the details on the current user
        conn
        |> json(%{
          status: "okay",
          data:
            Scoop.Utils.model_to_map(
              conn.assigns.current_user,
              [:email, :full_name, :id, :inserted_at, :updated_at]
            )
        })
    end
  end

  @doc """
  Return the posts feed to the user
  """
  def feed(conn, _params) do
    # Preload all user groups and posts
    user =
      conn.assigns.current_user
      |> Repo.preload(groups: [group: [posts: [:author, group: [:organisation]]]])

    # Accumulate the posts into a single list
    posts =
      Enum.reduce(user.groups, [], fn group_membership, acc ->
        acc ++ group_membership.group.posts
      end)

    # Convert the posts into serializable map
    data =
      Enum.map(posts, fn post ->
        # Convert the post, author and group into a JSON object
        Scoop.Utils.model_to_map(post, [:content, :id, :title, :inserted_at])
        |> Map.put(:author, Scoop.Utils.model_to_map(post.author, [:full_name]))
        |> Map.put(
          :group,
          Scoop.Utils.model_to_map(post.group, [:name])
          |> Map.put(:organisation, Scoop.Utils.model_to_map(post.group.organisation, [:name]))
        )
      end)

    # Sort the posts by the inserted date
    data = Enum.sort(data, fn a, b -> a.inserted_at > b.inserted_at end)

    # Return the posts
    json(conn, %{status: "okay", data: data})
  end

  @doc """
  Create a new user
  """
  def create(conn, params) do
    changeset = User.changeset(%User{}, params)

    case Repo.insert(changeset) do
      {:ok, _} ->
        # Return the new users token
        json(conn, %{status: "okay", data: %{token: changeset.changes.token}})

      {:error, changeset} ->
        # Error, return the changeset with the errors
        conn
        |> put_status(400)
        |> json(%{status: "error", errors: Scoop.Utils.changeset_error_to_string(changeset)})
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    # Get the user by email
    case Repo.get_by(User, email: email) do
      nil ->
        # Fetch the user by email.
        conn
        |> put_status(401)
        |> json(%{status: "error", errors: %{email: ["does not exist"]}})

      user ->
        # Verify that the provided password matches
        case Argon2.verify_pass(password, user.password) do
          true ->
            # Return the user token
            json(conn, %{status: "okay", data: %{token: user.token}})

          false ->
            # Incorrect password
            conn
            |> put_status(401)
            |> json(%{status: "error", errors: %{password: ["is incorrect"]}})
        end
    end
  end

  @doc """
  Fetch the user by ID.
  """
  def show(conn, %{"id" => user_id}) do
    # Fetch the user from the database.
    user = Repo.get(User, user_id)

    case user do
      nil ->
        conn
        |> put_status(404)
        |> json(%{errors: %{detail: "User not found"}})

      user ->
        json(conn, Scoop.Utils.model_to_map(user, [:email, :full_name]))
    end
  end
end
