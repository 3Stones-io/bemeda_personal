defmodule BemedaPersonal.DigitalSignatures.ProviderManagerTest do
  use ExUnit.Case, async: true

  alias BemedaPersonal.DigitalSignatures.ProviderManager
  alias BemedaPersonal.DigitalSignatures.Providers.Mock

  describe "get_provider/0" do
    test "returns mock provider by default" do
      assert {:ok, Mock} = ProviderManager.get_provider()
    end
  end

  describe "get_provider_name/0" do
    test "returns :mock by default" do
      assert :mock = ProviderManager.get_provider_name()
    end
  end

  describe "get_provider_config/0" do
    test "returns mock provider config" do
      result = ProviderManager.get_provider_config()
      assert {:ok, %{}} = result
    end
  end
end
