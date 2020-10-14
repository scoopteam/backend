defmodule ScoopWeb.Router do
  use ScoopWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ScoopWeb do
    pipe_through :api
  end
end
