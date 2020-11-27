defmodule Scoop.Utils do
  @doc """
  Convert the changeset errors into a JSON-encodable value for returning to the frontend.
  """
  def changeset_error_to_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  @doc """
  Convert a database model into a JSON-encodable map to return to the user.

  Fields must be whitelisted to be returned for safety.
  """
  def model_to_map(model, included_keys \\ nil) do
    all_keys = Map.keys(model)
    to_drop = MapSet.difference(MapSet.new(all_keys), MapSet.new(included_keys))
    Map.drop(model, to_drop |> MapSet.to_list())
  end
end
