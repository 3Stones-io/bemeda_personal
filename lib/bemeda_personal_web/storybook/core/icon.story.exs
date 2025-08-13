defmodule BemedaPersonalWeb.Storybook.Core.Icon do
  use PhoenixStorybook.Story, :component

  alias BemedaPersonalWeb.Components.Core.Icon
  alias PhoenixStorybook.Stories.Variation

  @type description :: String.t()

  @spec function() :: function()
  def function, do: &Icon.icon/1

  @spec description() :: description()
  def description, do: "Icon component using Heroicons library"

  @spec variations() :: [PhoenixStorybook.Stories.Variation.t()]
  def variations do
    [
      %Variation{
        id: :basic_icon,
        description: "Basic icon",
        attributes: %{
          name: "hero-home"
        }
      },
      %Variation{
        id: :solid_icon,
        description: "Solid icon variant",
        attributes: %{
          name: "hero-home-solid"
        }
      },
      %Variation{
        id: :mini_icon,
        description: "Mini icon variant",
        attributes: %{
          name: "hero-home-mini"
        }
      },
      %Variation{
        id: :sized_icons,
        description: "Icons with different sizes",
        template: """
        <div class="flex items-center gap-4">
          <.icon name="hero-star" class="w-4 h-4" />
          <.icon name="hero-star" class="w-6 h-6" />
          <.icon name="hero-star" class="w-8 h-8" />
          <.icon name="hero-star" class="w-10 h-10" />
          <.icon name="hero-star" class="w-12 h-12" />
        </div>
        """
      },
      %Variation{
        id: :colored_icons,
        description: "Icons with different colors",
        template: """
        <div class="flex items-center gap-4">
          <.icon name="hero-heart-solid" class="w-6 h-6 text-red-500" />
          <.icon name="hero-check-circle-solid" class="w-6 h-6 text-green-500" />
          <.icon name="hero-exclamation-triangle-solid" class="w-6 h-6 text-yellow-500" />
          <.icon name="hero-information-circle-solid" class="w-6 h-6 text-blue-500" />
          <.icon name="hero-x-circle-solid" class="w-6 h-6 text-gray-500" />
        </div>
        """
      },
      %Variation{
        id: :common_icons,
        description: "Commonly used icons",
        template: """
        <div class="grid grid-cols-6 gap-4">
          <div class="text-center">
            <.icon name="hero-home" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">Home</p>
          </div>
          <div class="text-center">
            <.icon name="hero-user" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">User</p>
          </div>
          <div class="text-center">
            <.icon name="hero-cog-6-tooth" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">Settings</p>
          </div>
          <div class="text-center">
            <.icon name="hero-magnifying-glass" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">Search</p>
          </div>
          <div class="text-center">
            <.icon name="hero-bell" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">Notifications</p>
          </div>
          <div class="text-center">
            <.icon name="hero-envelope" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">Email</p>
          </div>
          <div class="text-center">
            <.icon name="hero-calendar" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">Calendar</p>
          </div>
          <div class="text-center">
            <.icon name="hero-document-text" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">Document</p>
          </div>
          <div class="text-center">
            <.icon name="hero-chart-bar" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">Chart</p>
          </div>
          <div class="text-center">
            <.icon name="hero-briefcase" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">Briefcase</p>
          </div>
          <div class="text-center">
            <.icon name="hero-building-office" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">Office</p>
          </div>
          <div class="text-center">
            <.icon name="hero-arrow-right-on-rectangle" class="w-6 h-6 mx-auto mb-1" />
            <p class="text-xs">Logout</p>
          </div>
        </div>
        """
      }
    ]
  end
end
