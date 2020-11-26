defmodule Scoop.Repo.Migrations.UniqueConstraintUidAndGid do
  use Ecto.Migration

  def change do
    create unique_index(:group_memberships, [:group_id, :user_id])
  end
end
