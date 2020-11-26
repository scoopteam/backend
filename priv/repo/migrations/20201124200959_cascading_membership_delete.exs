defmodule Scoop.Repo.Migrations.CascadingMembershipDelete do
  use Ecto.Migration

  def change do
    drop_if_exists constraint(:organisation_memberships, "organisation_memberships_org_id_fkey")

    alter table(:organisation_memberships) do
      modify :org_id, references(:organisations, type: :integer, on_delete: :delete_all)
    end
  end
end
