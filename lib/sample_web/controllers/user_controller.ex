defmodule SampleWeb.UserController do
  use SampleWeb, :controller

  alias Sample.Accounts

  def index(conn, _) do
    users = Accounts.list_users()
    conn
    |> render("index.html", users: users)
  end
end
