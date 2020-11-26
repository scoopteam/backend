defmodule Scoop.OrganisationMembership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organisation_memberships" do
    field :permissions, {:array, :string}

    belongs_to :org, Scoop.Organisation
    belongs_to :user, Scoop.User

    timestamps()
  end

  @doc false
  def changeset(organisation_membership, attrs) do
    organisation_membership
    |> cast(attrs, [:permissions, :user_id, :org_id])
    |> validate_required([:permissions, :user_id, :org_id])
    |> unique_constraint(
      [:org_id, :user_id],
      name: :organisation_memberships_org_id_user_id_index,
      message: "is already used"
    )
  end
end
