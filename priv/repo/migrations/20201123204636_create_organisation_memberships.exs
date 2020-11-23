defmodule Scoop.Repo.Migrations.CreateOrganisationMemberships do
  use Ecto.Migration

  def change do
    create table(:organisation_memberships) do
      add :permissions, {:array, :string}
      add :user_id, references(:users, on_delete: :nothing)
      add :org_id, references(:organisations, on_delete: :nothing)

      timestamps()
    end

    create index(:organisation_memberships, [:user_id])
    create index(:organisation_memberships, [:org_id])
  end
end
