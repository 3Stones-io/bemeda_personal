defmodule BemedaPersonalWeb.Storybook.Core.Button do
  use PhoenixStorybook.Story, :component

  alias BemedaPersonalWeb.Components.Core.Button

  @type description :: String.t()

  @spec function() :: function()
  def function, do: &Button.button/1

  @spec description() :: description()
  def description, do: "Button component matching Figma design system"

  @spec variations() :: [PhoenixStorybook.Stories.Variation.t()]
  def variations do
    [
      %PhoenixStorybook.Stories.Variation{
        id: :primary,
        description: "Primary button - Main call to action",
        attributes: %{
          variant: "primary",
          size: "md"
        },
        slots: [
          "Save Changes"
        ]
      },
      %PhoenixStorybook.Stories.Variation{
        id: :secondary,
        description: "Secondary button - Alternative actions",
        attributes: %{
          variant: "secondary",
          size: "md"
        },
        slots: [
          "Cancel"
        ]
      },
      %PhoenixStorybook.Stories.Variation{
        id: :danger,
        description: "Danger button - Destructive actions",
        attributes: %{
          variant: "danger",
          size: "md"
        },
        slots: [
          "Delete"
        ]
      },
      %PhoenixStorybook.Stories.Variation{
        id: :sizes,
        description: "Button sizes",
        template: """
        <div class="flex items-center gap-4 flex-wrap">
          <.button variant="primary" size="sm">Small Button</.button>
          <.button variant="primary" size="md">Medium Button</.button>
          <.button variant="primary" size="lg">Large Button</.button>
        </div>
        """
      },
      %PhoenixStorybook.Stories.Variation{
        id: :all_variants,
        description: "All button variants",
        template: """
        <div class="space-y-4">
          <div class="flex items-center gap-4 flex-wrap">
            <.button variant="primary">Primary</.button>
            <.button variant="secondary">Secondary</.button>
            <.button variant="danger">Danger</.button>
          </div>
          <div class="flex items-center gap-4 flex-wrap">
            <.button variant="primary" disabled={true}>Disabled Primary</.button>
            <.button variant="secondary" disabled={true}>Disabled Secondary</.button>
            <.button variant="danger" disabled={true}>Disabled Danger</.button>
          </div>
        </div>
        """
      },
      %PhoenixStorybook.Stories.Variation{
        id: :with_icons,
        description: "Buttons with icons (icons component must be imported separately)",
        attributes: %{
          variant: "primary",
          size: "md"
        },
        slots: [
          "Button with Icon"
        ]
      }
    ]
  end
end
