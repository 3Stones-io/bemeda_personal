defmodule BemedaPersonalWeb.Components.Core.Flash do
  @moduledoc """
  Flash notification components for displaying messages to users.
  """

  use Phoenix.Component
  use Gettext, backend: BemedaPersonalWeb.Gettext

  import BemedaPersonalWeb.Components.Core.Icon

  alias Phoenix.LiveView.JS

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error, :warning], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  @spec flash(assigns()) :: rendered()
  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      phx-hook="FlashAutoDisappear"
      role="alert"
      class={[
        "fixed top-4 left-1/2 transform -translate-x-1/2 w-80 sm:w-96 z-50 rounded-lg p-4 shadow-lg border",
        @kind == :info && "bg-green-50 text-green-800 border-green-200",
        @kind == :error && "bg-red-50 text-red-800 border-red-200",
        @kind == :warning && "bg-orange-50 text-orange-800 border-orange-200"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-check-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :warning} name="hero-exclamation-triangle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button
        type="button"
        class="group absolute top-1 right-1 p-2"
        aria-label={dgettext("general", "close")}
      >
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  @spec flash_group(assigns()) :: rendered()
  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={dgettext("notifications", "Success!")} flash={@flash} />
      <.flash kind={:error} title={dgettext("notifications", "Error!")} flash={@flash} />
      <.flash kind={:warning} title={dgettext("general", "Attention")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={dgettext("notifications", "We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {dgettext("notifications", "Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={dgettext("notifications", "Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {dgettext("notifications", "Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @spec show(JS.t(), String.t()) :: JS.t()
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  @spec hide(JS.t(), String.t()) :: JS.t()
  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end
end
