defmodule Sample.AccountsTest do
  use Sample.DataCase

  alias Sample.Accounts

  describe "users" do
    alias Sample.Accounts.User

    @valid_attrs %{password: "some password", username: "some username"}
    @update_attrs %{password: "some updated password", username: "some updated username"}
    @invalid_attrs %{password: nil, username: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      [stored_user] = Accounts.list_users()
      assert stored_user.username == user.username
      assert stored_user.password_hash == user.password_hash
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      stored_user = Accounts.get_user!(user.id)
      assert stored_user.username == user.username
      assert stored_user.password_hash == user.password_hash
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.password == "some password"
      assert user.username == "some username"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.password == "some updated password"
      assert user.username == "some updated username"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      stored_user = Accounts.get_user!(user.id)
      assert user.username == stored_user.username
      assert user.password_hash == stored_user.password_hash
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "authenticate_user/2 with valid username/passowrd pair" do
      user = user_fixture()
      assert {:ok, stored_user} = Accounts.authenticate_user(user.username, "some password")
      assert stored_user.username == user.username
      assert stored_user.password_hash == user.password_hash
    end

    test "authenticate_user/2 with an invalid passowrd" do
      user = user_fixture()
      assert {:error, :invalid_credential} == Accounts.authenticate_user(user.username, "invalid password")
    end

    test "authenticate_user/2 with an invalid username" do
      user_fixture()
      assert {:error, :invalid_credential} == Accounts.authenticate_user("invalid username", "some password")
    end

    test "get_user_by/1 with a valid parameter" do
      user = user_fixture()
      stored_user = Accounts.get_user_by(username: user.username)
      assert user.username == stored_user.username
      assert user.password_hash == stored_user.password_hash
    end

    test "get_user_by/1 with an invalid parameter" do
      user_fixture()
      assert nil == Accounts.get_user_by(username: "invalid username")
    end
  end
end
