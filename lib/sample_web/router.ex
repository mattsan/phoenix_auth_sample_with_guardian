defmodule SampleWeb.Router do
  use SampleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug SampleWeb.Pipeline
  end

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/", SampleWeb do
    pipe_through [:browser, :auth]

    get "/", PageController, :index
    get "/login", SessionController, :new
    post "/login", SessionController, :login
  end

  scope "/", SampleWeb do
    pipe_through [:browser, :auth, :ensure_auth]

    resources "/users", UserController, only: [:index]
    delete "/logout", SessionController, :logout
  end

  # Other scopes may use custom stacks.
  # scope "/api", SampleWeb do
  #   pipe_through :api
  # end
end
