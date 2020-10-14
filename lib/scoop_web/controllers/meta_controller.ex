defmodule ScoopWeb.MetaController do
  use ScoopWeb, :controller

  def index(conn, _params) do
    json conn, %{
      "status" => "okay",
      "message" => "Hello!"
    }
  end
end
