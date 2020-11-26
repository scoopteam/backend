defmodule Scoop.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :text, :string
      add :group_id, references(:groups, on_delete: :delete_all)
      add :author_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:posts, [:group_id])
    create index(:posts, [:author_id])
  end
end
