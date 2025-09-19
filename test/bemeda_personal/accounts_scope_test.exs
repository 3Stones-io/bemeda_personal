defmodule BemedaPersonal.AccountsScopeTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User

  describe "get_user_by_email/2 with scope" do
    setup do
      user = user_fixture()
      scope = user_scope_fixture()
      %{user: user, scope: scope}
    end

    test "returns user when scope allows access", %{user: user, scope: scope} do
      # This test will FAIL initially - function doesn't accept scope yet
      result = Accounts.get_user_by_email(scope, user.email)
      assert %User{id: user_id} = result
      assert user_id == user.id
    end

    test "returns nil when email does not exist", %{scope: scope} do
      # This test will FAIL initially - function doesn't accept scope yet
      result = Accounts.get_user_by_email(scope, "nonexistent@example.com")
      assert is_nil(result)
    end

    test "returns user when scope is nil (allows unauthenticated access)" do
      user = user_fixture()
      # Allow unauthenticated access for login/registration flows
      result = Accounts.get_user_by_email(nil, user.email)
      assert %User{id: user_id} = result
      assert user_id == user.id
    end
  end

  describe "get_user!/2 with scope" do
    setup do
      user = user_fixture()
      scope = user_scope_fixture()
      %{user: user, scope: scope}
    end

    test "returns user when scope allows access", %{user: user, scope: scope} do
      # This test will FAIL initially - function doesn't accept scope yet
      result = Accounts.get_user!(scope, user.id)
      assert %User{id: user_id} = result
      assert user_id == user.id
    end

    test "raises when user does not exist", %{scope: scope} do
      # This test will FAIL initially - function doesn't accept scope yet
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(scope, "11111111-1111-1111-1111-111111111111")
      end
    end

    test "raises when scope is nil" do
      user = user_fixture()
      # This test will FAIL initially - function doesn't accept scope yet
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(nil, user.id)
      end
    end
  end

  describe "update_user_personal_info/3 with scope" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)
      %{user: user, scope: scope}
    end

    test "updates user when scope matches user", %{user: user, scope: scope} do
      update_attrs = %{city: "Updated City"}

      # This test will FAIL initially - function doesn't accept scope yet
      assert {:ok, updated_user} = Accounts.update_user_personal_info(scope, user, update_attrs)
      assert updated_user.city == "Updated City"
    end

    test "returns error when scope is nil", %{user: user} do
      update_attrs = %{city: "Updated City"}

      # This test will FAIL initially - function doesn't accept scope yet
      assert {:error, :unauthorized} = Accounts.update_user_personal_info(nil, user, update_attrs)
    end

    test "returns error when scope user doesn't match target user", %{user: user} do
      other_user = user_fixture()
      other_scope = Scope.for_user(other_user)
      update_attrs = %{city: "Updated City"}

      # This test will FAIL initially - function doesn't accept scope yet
      assert {:error, :unauthorized} =
               Accounts.update_user_personal_info(other_scope, user, update_attrs)
    end
  end
end
