defmodule Scoop.OrganisationMembership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organisation_memberships" do
    field :permissions, {:array, :string}
    field :user_id, :id
    field :org_id, :id

    timestamps()
  end

  @doc false
  def changeset(organisation_membership, attrs) do
    organisation_membership
    |> cast(attrs, [:permissions])
    |> validate_required([:permissions])
  end
end
