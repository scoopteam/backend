defmodule Scoop.Organisation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Scoop.Repo

  schema "organisations" do
    field :code, :string
    field :name, :string

    has_many :memberships, Scoop.OrganisationMembership, foreign_key: :org_id

    belongs_to :owner, Scoop.User

    timestamps()
  end

  defp generate_code() do
    # Generate a random 6 digit code
    Enum.map(1..6, fn _ ->
      Enum.random(
        Enum.to_list(?A..?Z)
        |> List.delete(?Q)
      )
    end) |> List.to_string
  end

  defp put_unique_code(changeset) do
    code = generate_code()

    case Repo.get_by(__MODULE__, code: code) do
      nil -> put_change(changeset, :code, code)
      _org -> put_unique_code(changeset)
    end
  end

  @doc false
  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name, :owner_id])
    |> put_unique_code()
    |> validate_required([:name, :code, :owner_id])
    |> unique_constraint(:code)
  end
end
