defmodule BemedaPersonal.Accounts.ScopeTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures

  alias BemedaPersonal.Accounts.Scope

  describe "for_user/1" do
    test "creates scope for valid user" do
      user = user_fixture()

      scope = Scope.for_user(user)

      assert %Scope{user: ^user, company: nil} = scope
    end

    test "returns nil for nil user" do
      refute Scope.for_user(nil)
    end
  end

  describe "put_company/2" do
    test "adds company to existing scope" do
      user = user_fixture(%{user_type: :employer})
      company = company_fixture(user)
      scope = Scope.for_user(user)

      updated_scope = Scope.put_company(scope, company)

      assert %Scope{user: ^user, company: ^company} = updated_scope
    end
  end

  describe "user_id/1" do
    test "returns user id when user exists" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert Scope.user_id(scope) == user.id
    end

    test "returns nil when user is nil" do
      scope = %Scope{user: nil, company: nil}

      refute Scope.user_id(scope)
    end
  end

  describe "company_id/1" do
    test "returns company id when company exists" do
      user = user_fixture(%{user_type: :employer})
      company = company_fixture(user)

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert Scope.company_id(scope) == company.id
    end

    test "returns nil when company is nil" do
      user = user_fixture()
      scope = Scope.for_user(user)

      refute Scope.company_id(scope)
    end
  end

  describe "system/0" do
    test "creates system scope" do
      scope = Scope.system()

      assert %Scope{system: true, user: nil, company: nil} = scope
    end
  end

  describe "put_state/2" do
    test "adds state to existing scope" do
      user = user_fixture()
      scope = Scope.for_user(user)

      updated_scope = Scope.put_state(scope, "active")

      assert %Scope{user: ^user, state: "active"} = updated_scope
    end
  end

  describe "has_access?/2" do
    test "returns true for system scope asking for system access" do
      scope = Scope.system()

      assert Scope.has_access?(scope, :system) == true
    end

    test "returns false when user is nil and asking for user access" do
      scope = %Scope{user: nil, company: nil}

      assert Scope.has_access?(scope, :user) == false
    end

    test "returns true when user exists and asking for user access" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert Scope.has_access?(scope, :user) == true
    end

    test "returns false when company is nil and asking for company access" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert Scope.has_access?(scope, :company) == false
    end

    test "returns true when company exists and asking for company access" do
      user = user_fixture(%{user_type: :employer})
      company = company_fixture(user)

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert Scope.has_access?(scope, :company) == true
    end

    test "returns false for unknown access types" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert Scope.has_access?(scope, :unknown) == false
    end
  end
end
