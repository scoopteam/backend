defmodule Scoop.Repo.Migrations.CreateOrganisations do
  use Ecto.Migration

  def change do
    create table(:organisations) do
      add :name, :string
      add :code, :string
      add :owner_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:organisations, [:code])
    create index(:organisations, [:owner_id])
  end
end
