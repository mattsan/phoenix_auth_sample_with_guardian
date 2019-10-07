defmodule SampleWeb.SessionController do
  use SampleWeb, :controller

  alias Sample.Accounts
  alias Sample.Accounts.User

  def new(conn, _) do
    changeset = Accounts.change_user(%User{})

    conn
    |> render("new.html", changeset: changeset)
  end

  def login(conn, %{"user" => %{"username" => username, "password" => password}}) do
    auth_result = Accounts.authenticate_user(username, password)

    case auth_result do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> Guardian.Plug.sign_in(SampleWeb.Guardian, user)
        |> IO.inspect()
        |> redirect(to: Routes.user_path(conn, :index))

      {:error, reason} ->
        conn
        |> put_flash(:error, to_string(reason))
        |> new(%{})
    end
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out(SampleWeb.Guardian, [])
    |> redirect(to: Routes.session_path(conn, :login))
  end
end
