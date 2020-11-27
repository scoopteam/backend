defmodule Scoop.Permissions do
  @doc """
  Check if a permission is in a permission array.
  """
  def has_perm?(perms, perm) do
    # Check if the perm is in the perms list
    perm in perms
  end

  @doc """
  Check if a user has any permission in the requested_perms list
  """
  def has_any_perm?(user_perms, requested_perms) do
    requested_perms
    # Build an array of each permissions value
    |> Enum.map(&(&1 in user_perms))
    # Return true if any of the values are true
    |> Enum.any?()
  end
end
