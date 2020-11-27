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
    pipe_through :private_api

    post "/org/join", OrganisationController, :join
    post "/org/:org_id/group/:group_id/bulk_add", GroupController, :bulk_add

    get "/user/feed", UserController, :feed

    resources "/org", OrganisationController, except: [:new, :edit] do
      resources "/group", GroupController, except: [:new, :edit] do
        resources "/post", PostController, except: [:new, :edit]
      end
    end
  end

  scope "/", ScoopWeb do
    pipe_through :public_api

    get "/", MetaController, :index

    resources "/user", UserController, except: [:new, :edit]
    post "/user/login", UserController, :login
  end

  scope "/" do
    pipe_through [:browser, :admin]
    live_dashboard "/dashboard"
  end
end
