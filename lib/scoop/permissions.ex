defmodule Scoop.Permissions do
  def has_perm?(perms, perm) do
    perm in perms
  end

  def has_any_perm?(user_perms, requested_perms) do
    requested_perms
    |> Enum.map(&(&1 in user_perms))
    |> Enum.any?()
  end
end
