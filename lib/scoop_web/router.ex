defmodule ScoopWeb.Router do
  use ScoopWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ScoopWeb do
    pipe_through :api

    get "/", MetaController, :index
  end
end
