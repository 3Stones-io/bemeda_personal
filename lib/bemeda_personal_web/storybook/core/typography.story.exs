defmodule BemedaPersonalWeb.Storybook.Core.Typography do
  use PhoenixStorybook.Story, :component

  alias BemedaPersonalWeb.Components.Core.Typography
  alias PhoenixStorybook.Stories.Variation

  @type description :: String.t()

  @spec function() :: function()
  def function, do: &Typography.heading/1

  @spec description() :: description()
  def description, do: "Typography components using design system scale"

  @spec variations() :: [PhoenixStorybook.Stories.Variation.t()]
  def variations do
    [
      %Variation{
        id: :heading_h1,
        description: "H1 Heading",
        attributes: %{
          level: "h1"
        },
        slots: [
          "Heading 1 - 96px"
        ]
      },
      %Variation{
        id: :heading_h2,
        description: "H2 Heading",
        attributes: %{
          level: "h2"
        },
        slots: [
          "Heading 2 - 60px"
        ]
      },
      %Variation{
        id: :heading_h3,
        description: "H3 Heading",
        attributes: %{
          level: "h3"
        },
        slots: [
          "Heading 3 - 48px"
        ]
      },
      %Variation{
        id: :heading_h4,
        description: "H4 Heading",
        attributes: %{
          level: "h4"
        },
        slots: [
          "Heading 4 - 34px"
        ]
      },
      %Variation{
        id: :heading_h5,
        description: "H5 Heading",
        attributes: %{
          level: "h5"
        },
        slots: [
          "Heading 5 - 24px"
        ]
      },
      %Variation{
        id: :heading_h6,
        description: "H6 Heading",
        attributes: %{
          level: "h6"
        },
        slots: [
          "Heading 6 - 20px"
        ]
      },
      %Variation{
        id: :typography_scale,
        description: "Complete typography scale",
        template: """
        <div class="space-y-6">
          <.heading level="h1">Heading 1 - Main Page Title</.heading>
          <.heading level="h2">Heading 2 - Section Title</.heading>
          <.heading level="h3">Heading 3 - Subsection Title</.heading>
          <.heading level="h4">Heading 4 - Card Title</.heading>
          <.heading level="h5">Heading 5 - Small Title</.heading>
          <.heading level="h6">Heading 6 - Micro Title</.heading>
          
          <div class="mt-8 space-y-4">
            <p class="text-body-1">Body 1 - This is the primary body text style used for main content. It provides good readability for longer passages of text.</p>
            <p class="text-body-2">Body 2 - This is the secondary body text style, slightly smaller than body-1. Used for supporting content.</p>
            <p class="text-subtitle">Subtitle - Used for subtitles and secondary headings that need less emphasis.</p>
            <p class="text-caption">Caption - Small text used for captions, labels, and helper text.</p>
            <p class="text-overline">OVERLINE - USED FOR LABELS AND CATEGORIES</p>
          </div>
        </div>
        """
      },
      %Variation{
        id: :text_utilities,
        description:
          "Text utility components (note: other typography components like section_heading, text, etc. are available in the main Typography module)",
        template: """
        <div class="space-y-6">
          <div>
            <h4 class="text-h5 mb-4">Typography Components Available:</h4>
            <ul class="list-disc list-inside space-y-2 text-gray-600">
              <li>heading - Main heading component with h1-h6 levels</li>
              <li>section_heading - Section headings</li>
              <li>subsection_heading - Subsection headings</li>
              <li>text - Regular text content</li>
              <li>small_text - Small text for secondary info</li>
              <li>caption - Caption text for labels</li>
              <li>text_link - Text links with styling</li>
            </ul>
            <p class="mt-4 text-sm text-gray-500">Import BemedaPersonalWeb.Components.Core.Typography to use these components.</p>
          </div>
        </div>
        """
      }
    ]
  end
end
