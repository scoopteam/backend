defmodule Scoop.GroupMembership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "group_memberships" do
    belongs_to :user, Scoop.User
    belongs_to :group, Scoop.Group
    belongs_to :organisation_membership, Scoop.OrganisationMembership

    timestamps()
  end

  @doc false
  def changeset(group_membership, attrs) do
    group_membership
    |> cast(attrs, [:user_id, :group_id, :organisation_membership_id])
    |> validate_required([:user_id, :group_id, :organisation_membership_id])
    |> unique_constraint(
      [:group_id, :user_id],
      name: :group_memberships_group_id_user_id_index,
      message: "is already a member"
    )
  end
end
