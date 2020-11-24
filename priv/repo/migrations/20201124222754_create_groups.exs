defmodule Scoop.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add :name, :string
      add :public, :boolean, default: false, null: false
      add :auto_subscribe, :boolean, default: false, null: false
      add :organisation_id, references(:organisations, on_delete: :delete_all)

      timestamps()
    end

    create index(:groups, [:organisation_id])
  end
end
