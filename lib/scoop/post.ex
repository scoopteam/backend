defmodule Scoop.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :text, :string
    field :title, :string

    belongs_to :author, Scoop.User
    belongs_to :group, Scoop.Group

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :text, :author_id, :group_id])
    |> validate_required([:title, :text, :author_id, :group_id])
  end
end
