defmodule Scoop.Repo.Migrations.SwitchContentToRich do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      remove :text
      add :content, {:array, :map}
    end
  end
end
