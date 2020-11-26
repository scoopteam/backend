defmodule Scoop.Repo.Migrations.ContentToString do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      remove :content
      add :content, :string
    end
  end
end
