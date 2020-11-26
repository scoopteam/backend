defmodule Scoop.Repo.Migrations.CreateGroupMemberships do
  use Ecto.Migration

  def change do
    create table(:group_memberships) do
      add :organisation_membership_id,
          references(:organisation_memberships, on_delete: :delete_all)

      add :group_id, references(:groups, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:group_memberships, [:organisation_membership_id])
    create index(:group_memberships, [:group_id])
    create index(:group_memberships, [:user_id])
  end
end
