defmodule Scoop.Repo.Migrations.TearDownOrgMembershipOnUserDelete do
  use Ecto.Migration

  def change do
      drop_if_exists constraint(:organisation_memberships, "organisation_memberships_user_id_fkey")

      alter table(:organisation_memberships) do
        modify :user_id, references(:users, type: :integer, on_delete: :delete_all)
      end
  end
end
