defmodule BemedaPersonalWeb.Components do
  @moduledoc """
  Component registry providing easy access to the design system components.

  Use this module to import all design system components and utilities
  in a consistent way across the application.

  ## Usage

      use BemedaPersonalWeb.Components

  This will import all core design system components and make them available
  as function components in your LiveViews and templates.
  """

  defmacro __using__(_opts) do
    quote do
      # Core design system components
      import BemedaPersonalWeb.Components.Core.Button
      import BemedaPersonalWeb.Components.Core.Card
      import BemedaPersonalWeb.Components.Core.Error
      import BemedaPersonalWeb.Components.Core.Flash
      import BemedaPersonalWeb.Components.Core.Form
      import BemedaPersonalWeb.Components.Core.Header
      import BemedaPersonalWeb.Components.Core.Icon
      import BemedaPersonalWeb.Components.Core.List
      import BemedaPersonalWeb.Components.Core.Modal
      import BemedaPersonalWeb.Components.Core.Navigation
      import BemedaPersonalWeb.Components.Core.Typography

      # JavaScript utilities
      import BemedaPersonalWeb.Components.Core.JsUtilities

      # Spacing utilities
      import BemedaPersonalWeb.Components.Shared.Spacing

      # Domain component aliases for easy access
      alias BemedaPersonalWeb.Components.Company
      alias BemedaPersonalWeb.Components.Document
      alias BemedaPersonalWeb.Components.Job
      alias BemedaPersonalWeb.Components.JobApplication
      alias BemedaPersonalWeb.Components.Shared

      # Legacy alias for backward compatibility
      alias BemedaPersonalWeb.Components.Shared.SharedComponents
    end
  end
end
