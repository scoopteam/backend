defmodule Scoop.Utils do    
    def changeset_error_to_string(changeset) do
        Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
        end)
        end)
    end

    def model_to_map(model, included_keys \\ nil) do
        all_keys = Map.keys(model)
        to_drop = MapSet.difference(MapSet.new(all_keys), MapSet.new(included_keys))
        Map.drop(model, to_drop)
    end
end
