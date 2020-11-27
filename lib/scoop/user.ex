defmodule Scoop.User do
  use Ecto.Schema
  import Ecto.Changeset

  import Argon2

  schema "users" do
    field :email, :string
    field :full_name, :string
    field :password, :string
    field :token, :string

    has_many :memberships, Scoop.OrganisationMembership
    has_many :groups, Scoop.GroupMembership

    timestamps()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    # Hash the provided password and update the changeset
    change(changeset, add_hash(password, hash_key: :password))
  end

  # If the changeset is invalid don't attempt to hash the paassword
  defp put_pass_hash(changeset), do: changeset

  # Generate a random user token for API access.
  defp generate_user_token(changeset) do
    # Generate 20 random bytes and encode them into hex
    token = :crypto.strong_rand_bytes(20) |> Base.encode16(case: :lower)

    # Add the change to the changeset
    put_change(changeset, :token, token)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :full_name])
    |> validate_required([:email, :password, :full_name])
    |> validate_length(:email, max: 100)
    |> validate_length(:password, min: 8, max: 100)
    |> validate_change(:password, fn :password, password ->
      has_number = Enum.map(?0..?9, fn c ->
        c in String.to_charlist(password)
      end)
      |> Enum.any?

      if not has_number do
        [password: "must contain a number"]
      else
        []
      end
    end)
    |> validate_format(:email, ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i,
      message: "must be a valid email"
    )
    |> unique_constraint(:email)
    |> put_pass_hash()
    |> generate_user_token()
  end
end
