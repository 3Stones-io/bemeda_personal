defmodule BemedaPersonalWeb.Storybook.Core.Modal do
  use PhoenixStorybook.Story, :component

  alias BemedaPersonalWeb.Components.Core.Modal
  alias PhoenixStorybook.Stories.Variation

  @type description :: String.t()

  @spec function() :: function()
  def function, do: &Modal.modal/1

  @spec description() :: description()
  def description, do: "Modal dialog component for overlays and popups"

  @spec variations() :: [PhoenixStorybook.Stories.Variation.t()]
  def variations do
    [
      %Variation{
        id: :basic_modal,
        description: "Basic modal with close button",
        attributes: %{
          id: "basic-modal",
          show: true
        },
        slots: [
          """
          <div class="p-6">
            <h2 class="text-lg font-semibold mb-4">Modal Title</h2>
            <p class="text-gray-600 mb-4">This is a basic modal with some content inside.</p>
            <div class="flex gap-2 justify-end">
              <button class="px-4 py-2 bg-gray-200 rounded">Cancel</button>
              <button class="px-4 py-2 bg-primary-600 text-white rounded">Confirm</button>
            </div>
          </div>
          """
        ]
      },
      %Variation{
        id: :without_close_button,
        description: "Modal without close button",
        attributes: %{
          id: "no-close-modal",
          show: true,
          show_close_button: false
        },
        slots: [
          """
          <div class="p-6">
            <h2 class="text-lg font-semibold mb-4">Important Action</h2>
            <p class="text-gray-600 mb-4">This modal requires explicit action to close.</p>
            <div class="flex gap-2 justify-end">
              <button class="px-4 py-2 bg-danger-600 text-white rounded">Delete</button>
              <button class="px-4 py-2 bg-gray-200 rounded">Cancel</button>
            </div>
          </div>
          """
        ]
      },
      %Variation{
        id: :form_modal,
        description: "Modal with form content",
        attributes: %{
          id: "form-modal",
          show: true
        },
        slots: [
          """
          <div class="p-6">
            <h2 class="text-lg font-semibold mb-4">Edit Profile</h2>
            <form class="space-y-4">
              <div>
                <label class="block text-sm font-medium mb-1">Name</label>
                <input type="text" class="w-full px-3 py-2 border rounded" value="John Doe" />
              </div>
              <div>
                <label class="block text-sm font-medium mb-1">Email</label>
                <input type="email" class="w-full px-3 py-2 border rounded" value="john@example.com" />
              </div>
              <div class="flex gap-2 justify-end pt-4">
                <button type="button" class="px-4 py-2 bg-gray-200 rounded">Cancel</button>
                <button type="submit" class="px-4 py-2 bg-primary-600 text-white rounded">Save Changes</button>
              </div>
            </form>
          </div>
          """
        ]
      },
      %Variation{
        id: :scrollable_content,
        description: "Modal with scrollable content",
        attributes: %{
          id: "scrollable-modal",
          show: true
        },
        slots: [
          """
          <div class="p-6">
            <h2 class="text-lg font-semibold mb-4">Terms and Conditions</h2>
            <div class="max-h-96 overflow-y-auto pr-2">
              <p class="text-gray-600 mb-4">Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
              <p class="text-gray-600 mb-4">Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p>
              <p class="text-gray-600 mb-4">Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.</p>
              <p class="text-gray-600 mb-4">Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
              <p class="text-gray-600 mb-4">Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.</p>
              <p class="text-gray-600 mb-4">Totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
            </div>
            <div class="flex gap-2 justify-end pt-4">
              <button class="px-4 py-2 bg-gray-200 rounded">Decline</button>
              <button class="px-4 py-2 bg-primary-600 text-white rounded">Accept</button>
            </div>
          </div>
          """
        ]
      }
    ]
  end
end
