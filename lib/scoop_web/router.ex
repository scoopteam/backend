defmodule ScoopWeb.Router do
  use ScoopWeb, :router
  import Plug.BasicAuth
  import Phoenix.LiveDashboard.Router

  pipeline :api do
    plug CORSPlug, origin: ["http://dev.seph.club:3000", "https://scoop-frontend.netlify.app"]
    plug :accepts, ["json"]
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin do
    plug :basic_auth, username: "admin", password: (if Mix.env() == :prod do System.fetch_env!("ADMIN_PASSWORD") else "password" end)
  end


  scope "/", ScoopWeb do
    pipe_through :api

    get "/", MetaController, :index

    resources "/users", UserController, except: [:new, :edit]
  end

  scope "/" do
    pipe_through [:browser, :admin]
    live_dashboard "/dashboard"
  end
end
