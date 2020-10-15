defmodule Scoop.User do
  use Ecto.Schema
  import Ecto.Changeset

  import Argon2

  schema "users" do
    field :email, :string
    field :full_name, :string
    field :password, :string

    timestamps()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes:
      %{password: password}} = changeset) do
    change(changeset, add_hash(password, hash_key: :password))
  end

  defp put_pass_hash(changeset), do: changeset

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :full_name])
    |> validate_required([:email, :password, :full_name])
    |> validate_format(:password, ~r/.+\d.+/, message: "must include a number")
    |> validate_format(:email, ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i, message: "must be a valid email")
    |> validate_length(:password, min: 8)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end
end
