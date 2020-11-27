defmodule Scoop.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :content, :string
    field :title, :string

    belongs_to :author, Scoop.User
    belongs_to :group, Scoop.Group

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :content, :author_id, :group_id])
    |> validate_length(:content, max: 2000)
    |> validate_required([:title, :content, :author_id, :group_id])
  end
end
