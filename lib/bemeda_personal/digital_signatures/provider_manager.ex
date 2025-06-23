defmodule BemedaPersonal.DigitalSignatures.ProviderManager do
  @moduledoc """
  Manages digital signature providers and their configurations.
  """

  alias BemedaPersonal.DigitalSignatures.Providers.Mock
  alias BemedaPersonal.DigitalSignatures.Providers.SignWell

  @providers %{
    mock: Mock,
    signwell: SignWell
  }

  @spec get_provider() :: {:ok, module()} | {:error, String.t()}
  def get_provider do
    provider_name = get_provider_name()

    case Map.get(@providers, provider_name) do
      nil -> {:error, "Unknown provider: #{provider_name}"}
      provider_module -> {:ok, provider_module}
    end
  end

  @spec get_provider_config() :: {:ok, map()} | {:error, String.t()}
  def get_provider_config do
    provider_name = get_provider_name()
    config = Application.get_env(:bemeda_personal, :digital_signatures, [])
    providers_config = config[:providers] || %{}

    case Map.get(providers_config, provider_name) do
      nil -> {:error, "No configuration found for provider: #{provider_name}"}
      provider_config -> {:ok, provider_config}
    end
  end

  @spec get_provider_name() :: atom()
  def get_provider_name do
    config = Application.get_env(:bemeda_personal, :digital_signatures, [])
    config[:provider] || :mock
  end
end
