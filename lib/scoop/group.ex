defmodule Scoop.Group do
  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field :auto_subscribe, :boolean, default: false
    field :name, :string
    field :public, :boolean, default: false

    belongs_to :organisation, Scoop.Organisation

    has_many :posts, Scoop.Post

    timestamps()
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :public, :auto_subscribe, :organisation_id])
    |> validate_required([:name, :public, :auto_subscribe, :organisation_id])
    |> unique_constraint(:name)
  end
end
