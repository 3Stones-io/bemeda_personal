defmodule BemedaPersonalWeb.Storybook.Core.Card do
  use PhoenixStorybook.Story, :component

  alias BemedaPersonalWeb.Components.Core.Card
  alias PhoenixStorybook.Stories.Variation

  @type description :: String.t()

  @spec function() :: function()
  def function, do: &Card.card/1

  @spec description() :: description()
  def description, do: "Card component for content containers"

  @spec variations() :: [PhoenixStorybook.Stories.Variation.t()]
  def variations do
    [
      %Variation{
        id: :default,
        description: "Default card",
        attributes: %{},
        slots: [
          """
          <div class="p-4">
            <h3 class="text-lg font-semibold mb-2">Default Card</h3>
            <p class="text-gray-600">This is a default card with standard styling.</p>
          </div>
          """
        ]
      },
      %Variation{
        id: :elevated,
        description: "Elevated card with shadow",
        attributes: %{
          variant: "elevated"
        },
        slots: [
          """
          <div class="p-4">
            <h3 class="text-lg font-semibold mb-2">Elevated Card</h3>
            <p class="text-gray-600">This card has an elevated appearance with shadow.</p>
          </div>
          """
        ]
      },
      %Variation{
        id: :outlined,
        description: "Outlined card with border",
        attributes: %{
          variant: "outlined"
        },
        slots: [
          """
          <div class="p-4">
            <h3 class="text-lg font-semibold mb-2">Outlined Card</h3>
            <p class="text-gray-600">This card has a border instead of shadow.</p>
          </div>
          """
        ]
      },
      %Variation{
        id: :flat,
        description: "Flat card with no shadow or border",
        attributes: %{
          variant: "flat"
        },
        slots: [
          """
          <div class="p-4">
            <h3 class="text-lg font-semibold mb-2">Flat Card</h3>
            <p class="text-gray-600">This card has no shadow or border.</p>
          </div>
          """
        ]
      },
      %Variation{
        id: :padding_variations,
        description: "Card padding variations",
        template: """
        <div class="space-y-4">
          <.card padding="none">
            <div class="p-4 bg-gray-50">No padding (content provides its own)</div>
          </.card>
          <.card padding="small">
            <div>Small padding</div>
          </.card>
          <.card padding="default">
            <div>Default padding</div>
          </.card>
          <.card padding="large">
            <div>Large padding</div>
          </.card>
        </div>
        """
      },
      %Variation{
        id: :all_variants,
        description: "All card variants",
        template: """
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.card variant="default">
            <div class="p-4">
              <h4 class="font-semibold mb-2">Default</h4>
              <p class="text-sm text-gray-600">Standard card appearance</p>
            </div>
          </.card>
          <.card variant="elevated">
            <div class="p-4">
              <h4 class="font-semibold mb-2">Elevated</h4>
              <p class="text-sm text-gray-600">Card with shadow effect</p>
            </div>
          </.card>
          <.card variant="outlined">
            <div class="p-4">
              <h4 class="font-semibold mb-2">Outlined</h4>
              <p class="text-sm text-gray-600">Card with border</p>
            </div>
          </.card>
          <.card variant="flat">
            <div class="p-4">
              <h4 class="font-semibold mb-2">Flat</h4>
              <p class="text-sm text-gray-600">No shadow or border</p>
            </div>
          </.card>
        </div>
        """
      }
    ]
  end
end
