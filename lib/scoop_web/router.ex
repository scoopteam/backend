defmodule ScoopWeb.Router do
  use ScoopWeb, :router
  import Plug.BasicAuth
  import Phoenix.LiveDashboard.Router

  pipeline :public_api do
    plug :accepts, ["json"]
    plug ScoopWeb.Plugs.SetCurrentUser
  end

  pipeline :private_api do
    plug :accepts, ["json"]
    plug ScoopWeb.Plugs.SetCurrentUser, auth_required: true
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin do
    plug :basic_auth,
      username: "admin",
      password:
        (if Mix.env() == :prod do
          System.fetch_env!("ADMIN_PASSWORD")
        else
          "password"
        end)
  end

  scope "/", ScoopWeb do
    pipe_through :public_api

    get "/", MetaController, :index

    resources "/user", UserController, except: [:new, :edit]
    post "/user/login", UserController, :login
  end

  scope "/", ScoopWeb do
    pipe_through :private_api

    resources "/org", OrganisationController, except: [:new, :edit] do
      resources "/group", GroupController, except: [:new, :edit]
    end

    post "/org/join", OrganisationController, :join
  end

  scope "/" do
    pipe_through [:browser, :admin]
    live_dashboard "/dashboard"
  end
end
