# Phoenix Authentication Sample with Guardian

- [guardian](https://hex.pm/packages/guardian)
- [argon2_elixir](https://hex.pm/packages/argon2_elixir)

## 作成する内容

### Schema

- table: users
  - string username
  - string password_hash

### Routing

| # | helper       | method | path    | controller        | action |
|--:|--------------|--------|---------|-------------------|--------|
| 1 | session_path | GET    | /login  | SessionController | new    |
| 2 | session_path | POST   | /login  | SessionController | login  |
| 3 | session_path | DELETE | /logout | SessionController | logout |
| 4 | user_path    | GET    | /users  | UserController    | index  |

## プロジェクトを作る

```sh
$ mix phx.new sample
```

### DB を作成する

```sh
$ mix ecto.create
```

## users テーブルを作成する


```sh
$ mix phx.gen.context Accounts User users username:string:unique password_hash:string
```

マイグレーションファイルを編集する

```diff
 defmodule Sample.Repo.Migrations.CreateUsers do
   use Ecto.Migration

   def change do
     create table(:users) do
-      add :username, :string
-      add :password_hash, :string null: false
+      add :username, :string, null: false
+      add :password_hash, :string, null: false

       timestamps()
     end

     create unique_index(:users, [:username])
   end
 end
```

マイグレーションを実行する。

```sh
$ mix ecto.migrate
```

## パスワードハッシュを保存する仕組みを用意する

パッケージを追加する。

```diff
--- a/mix.exs
+++ b/mix.exs
@@ -42,7 +42,8 @@ defmodule Sample.MixProject do
       {:phoenix_live_reload, "~> 1.2", only: :dev},
       {:gettext, "~> 0.11"},
       {:jason, "~> 1.0"},
-      {:plug_cowboy, "~> 2.0"}
+      {:plug_cowboy, "~> 2.0"},
+      {:argon2_elixir, "~> 2.0"}
     ]
   end
```

```sh
$ mix deps.get
```

schema ファイルを編集する。

1. virtual field の `password` を追加する
2. `changeset/2` で受け取るパラメータを `username` と `password` に変更する
3. changeset が valid な場合、`password_hash` に `password` を `argon2_elixir` でハッシュ化した値を設定する


```diff
--- a/lib/sample/accounts/user.ex
+++ b/lib/sample/accounts/user.ex
@@ -5,6 +5,7 @@ defmodule Sample.Accounts.User do
   schema "users" do
     field :password_hash, :string
     field :username, :string
+    field :password, :string, virtual: true

     timestamps()
   end
@@ -12,8 +13,20 @@ defmodule Sample.Accounts.User do
   @doc false
   def changeset(user, attrs) do
     user
-    |> cast(attrs, [:username, :password_hash])
-    |> validate_required([:username, :password_hash])
+    |> cast(attrs, [:username, :password])
+    |> validate_required([:username, :password])
     |> unique_constraint(:username)
+    |> put_password_hash()
+  end
+
+  defp put_password_hash(changeset) do
+    case changeset do
+      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
+        changeset
+        |> put_change(:password_hash, Argon2.hash_pwd_salt(password))
+
+      _ ->
+        changeset
+    end
   end
 end
 ```

 格納する値を変更したことでテストが失敗するようになるので、テストも合わせて修正する。

## 認証のための関数を追加する

`Accounts` に、username と password で認証する関数 `authenticate_user/2` を追加する。

```elixir
  def authenticate_user(username, password) do
    query = from u in User, where: u.username == ^username
    user = Repo.one(query) |> Repo.preload(:credential)

    cond do
      user && Argon2.verify_pass(password, user.credential.password_hash) ->
        {:ok, user}

      user ->
        Argon2.no_user_verify()
        {:error, :invalid_credential}

      true ->
        {:error, :invalid_credential}
    end
  end
```

認証できたら user のレコードを返す。

## guardian を追加する

```diff
--- a/mix.exs
+++ b/mix.exs
@@ -43,7 +43,8 @@ defmodule Sample.MixProject do
       {:gettext, "~> 0.11"},
       {:jason, "~> 1.0"},
       {:plug_cowboy, "~> 2.0"},
-      {:argon2_elixir, "~> 2.0"}
+      {:argon2_elixir, "~> 2.0"},
+      {:guardian, "~> 2.0"}
     ]
   end
```

```sh
$ mix deps.get
```

## module Guardian を追加する

`lib/sample_web/guardian.ex`

```elixir
defmodule SampleWeb.Guardian do
  use Guardian, otp_app: :sample

  alias Sample.Accounts

  def subject_for_token(resource, _claims) do
    {:ok, resource.username}
  end

  def resource_from_claims(%{"sub" => username}) do
    case Accounts.get_user_by(username: username) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end
end
```

`SampleWeb.Guardian.resource_not_found/1` で `username` で検索できるように `Sample.Accounts.get_user_by/1` を追加する。

```elixir
  def get_user_by(params), do: Repo.get_by(User, params)
```

## ErrorHandler を追加する

```elixir
defmodule SampleWeb.ErrorHandler do
  @behaviour Guardian.Plug.ErrorHandler

  import Plug.Conn

  def auth_error(conn, {type, _reason}, _opts) do
    body = to_string(type)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(401, body)
  end
end
```

## Pipeline を追加する

```elixir
defmodule SampleWeb.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :hello,
    error_handler: SampleWeb.ErrorHandler,
    module: SampleWeb.Guardian

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.LoadResource, allow_blank: true
end
```

## config に guardian の secret key を設定する

## ユーザ一覧のページを作る

### cntroller を作る

### view を作る

### template を作る

### routing を追加する

### 確認

```
iex(3)> Sample.Accounts.create_user(%{username: "foobar", password: "foobarbaz"})
```

http://localhost:4000/users


## routing に認証を追加する

## login/logout 機能を追加する

### routing を追加する

### controller & view を追加する

### ログインページを追加する

### ログアウトを追加する
