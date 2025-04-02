defmodule BemedaPersonalWeb.Components.ResumeComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.DateUtils
  alias Phoenix.LiveView.JS

  attr :id, :string, default: nil
  attr :title, :string, required: true
  attr :add_path, :string
  attr :items, :any, required: true
  attr :empty_state_message, :string, required: true
  attr :can_update_resume, :boolean, default: false

  slot :resume_item, required: true

  @spec resume_section(map()) :: Phoenix.LiveView.Rendered.t()
  def resume_section(assigns) do
    ~H"""
    <div class="bg-white shadow-sm outline outline-gray-200 rounded-lg overflow-hidden mb-8">
      <div class="p-6">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-xl font-bold text-gray-800">{@title}</h2>
          <.link
            :if={@can_update_resume}
            navigate={@add_path}
            class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-md flex items-center"
          >
            <.icon name="hero-plus" class="h-5 w-5 mr-2" /> Add
          </.link>
        </div>

        <div class="space-y-6" id={@id} phx-update="stream">
          <p class="only:block hidden text-center py-8 text-gray-500" id={"empty-state-#{@id}"}>
            {@empty_state_message}
          </p>

          <div
            :for={{dom_id, item} <- @items}
            class="border-b border-gray-200 pb-4 last-of-type:border-b-0 last-of-type:pb-0"
            id={dom_id}
          >
            {render_slot(@resume_item, item)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :item, :map, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :extra_info, :string, default: nil
  attr :edit_path, :string, required: true
  attr :delete_event, :string, required: true
  attr :can_update_resume, :boolean, default: false

  @spec resume_item(map()) :: Phoenix.LiveView.Rendered.t()
  def resume_item(assigns) do
    ~H"""
    <div class="flex justify-between">
      <div>
        <h3 class="font-semibold text-gray-800">{@title}</h3>
        <p class="text-gray-600">{@subtitle}</p>
        <p :if={@extra_info} class="text-gray-500">{@extra_info}</p>
        <p class="text-sm text-gray-500">
          {DateUtils.format_date(@item.start_date)} - {if @item.current,
            do: "Present",
            else: DateUtils.format_date(@item.end_date)}
        </p>
        <p
          :if={@item.description}
          class="mt-2 text-gray-600 truncate-text"
          id={"description-#{@item.id}"}
          phx-hook="TextTruncate"
          data-truncate-length="150"
        >
          {@item.description}
        </p>
      </div>

      <div :if={@can_update_resume} class="flex space-x-2">
        <.link navigate={@edit_path} class="text-blue-500 hover:text-blue-600" title="Edit">
          <.icon name="hero-pencil-square" class="h-5 w-5" />
        </.link>

        <.link
          phx-click={
            JS.push(@delete_event,
              value: %{id: @item.id}
            )
            |> JS.hide(to: "##{@id}")
          }
          data-confirm="Are you sure you want to delete this entry?"
          class="text-red-500 hover:text-red-600"
          title="Delete"
          id={"#{@delete_event}-#{@item.id}"}
        >
          <.icon name="hero-trash" class="h-5 w-5" />
        </.link>
      </div>
    </div>
    """
  end

  attr :resume, :map, required: true
  attr :title, :string, default: "Resume"
  attr :email_fallback, :string, default: "Email not provided"
  attr :headline_default, :string, default: "Professional"
  attr :summary_default, :string, default: "No summary provided"
  attr :can_update_resume, :boolean, default: false
  slot :actions

  @spec resume_profile(map()) :: Phoenix.LiveView.Rendered.t()
  def resume_profile(assigns) do
    ~H"""
    <div class="bg-white shadow-sm outline outline-gray-200 rounded-lg overflow-hidden mb-8">
      <div class="p-6">
        <div class="flex justify-between items-center mb-4">
          <h1 class="text-2xl font-bold text-gray-800">{@title}</h1>
          <div class="flex space-x-2">
            {render_slot(@actions)}
          </div>
        </div>

        <.resume_header
          resume={@resume}
          headline_default={@headline_default}
          summary_default={@summary_default}
        />

        <.resume_contact_info resume={@resume} email_fallback={@email_fallback} />
      </div>
    </div>
    """
  end

  attr :icon_name, :string, required: true

  slot :content, required: true

  defp profile_info_item(assigns) do
    ~H"""
    <p class="flex items-center">
      <.icon name={@icon_name} class="h-5 w-5 mr-2 text-gray-500" />
      {render_slot(@content)}
    </p>
    """
  end

  attr :resume, :map, required: true
  attr :headline_default, :string, default: "Professional"
  attr :summary_default, :string, default: "No summary provided"

  defp resume_header(assigns) do
    ~H"""
    <div class="mb-6">
      <h2 class="text-xl font-semibold text-gray-700 mb-2">
        {@resume.headline || @headline_default}
      </h2>
      <p
        class="text-gray-600 truncate-text"
        id="resume-summary"
        phx-hook="TextTruncate"
        data-truncate-length="200"
      >
        {@resume.summary || @summary_default}
      </p>
    </div>
    """
  end

  attr :resume, :map, required: true
  attr :email_fallback, :string, default: "Email not provided"

  defp resume_contact_info(assigns) do
    ~H"""
    <div class="grid grid-cols-2 gap-4 text-sm text-gray-600">
      <.profile_info_item icon_name="hero-map-pin">
        <:content>
          {@resume.location || "Location not specified"}
        </:content>
      </.profile_info_item>

      <.profile_info_item icon_name="hero-envelope">
        <:content>
          {@resume.contact_email || @email_fallback}
        </:content>
      </.profile_info_item>

      <.profile_info_item icon_name="hero-phone">
        <:content>
          {@resume.phone_number || "Phone not specified"}
        </:content>
      </.profile_info_item>

      <.profile_info_item icon_name="hero-link">
        <:content>
          <%= if @resume.website_url do %>
            <a href={@resume.website_url} target="_blank" class="text-blue-500 hover:underline">
              {@resume.website_url}
            </a>
          <% else %>
            Website not specified
          <% end %>
        </:content>
      </.profile_info_item>
    </div>
    """
  end
end
