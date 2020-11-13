defmodule Scoop.Repo.Migrations.AddUniqueConstraintOnToken do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:token])
  end
end
