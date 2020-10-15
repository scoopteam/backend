defmodule Scoop.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :password, :string
      add :full_name, :string

      timestamps()
    end

  end
end
