defmodule Scoop.Repo.Migrations.AddUniqueKeyToOrgMembership do
  use Ecto.Migration

  def change do
    create unique_index(:organisation_memberships, [:org_id, :user_id])
  end
end
