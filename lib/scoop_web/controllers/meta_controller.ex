defmodule ScoopWeb.MetaController do
  use ScoopWeb, :controller

  @doc """
  Say hello from Scoop!
  """
  def index(conn, _params) do
    json(conn, %{
      "status" => "okay",
      "message" => "Hello from Scoop!"
    })
  end
end
