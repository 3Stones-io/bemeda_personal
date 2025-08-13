defmodule BemedaPersonalWeb.Components.Core.Form do
  @moduledoc """
  Form components using design tokens for consistent form styling.

  Provides standardized form inputs, labels, and validation messages
  that follow the design system for consistent user experience.
  """

  use Phoenix.Component
  use Gettext, backend: BemedaPersonalWeb.Gettext

  import BemedaPersonalWeb.Components.Core.Error, only: [translate_error: 1, error: 1]
  import BemedaPersonalWeb.Components.Core.JsUtilities, only: [show: 1]

  alias Phoenix.HTML.Form

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  @spec simple_form(assigns()) :: rendered()
  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any, default: nil

  attr :type, :string,
    default: "text",
    values:
      ~w(chat-input checkbox color date datetime-local email file hidden month multi-select number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :label_class, :string,
    default: "block text-sm font-semibold leading-6 text-secondary-800",
    doc: "the class for the label"

  attr :input_class, :string, default: nil, doc: "the class for the input"
  attr :nested_input?, :boolean, default: false, doc: "the nested input flag"
  attr :show_nested_input, :string, default: nil, doc: "the nested input flag"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :nested_input, doc: "the slot for the nested input"

  @spec input(assigns()) :: rendered()
  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    label_class =
      if(errors != [],
        do: "block text-sm font-semibold leading-6 text-danger-600",
        else: assigns.label_class
      )

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign(:label_class, label_class)
    |> assign_new(:name, fn ->
      if assigns.multiple || assigns.type == "multi-select",
        do: field.name <> "[]",
        else: field.name
    end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  @spec input(assigns()) :: rendered()
  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label class={[
        "flex items-center gap-4 text-sm leading-6 text-secondary-600",
        @label_class
      ]}>
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={[
            "peer rounded border-secondary-300 text-secondary-900 focus:ring-0",
            @input_class
          ]}
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @spec input(assigns()) :: rendered()
  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label for={@id} class={@label_class} required={@rest[:required]}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-md border bg-white shadow-sm focus:ring-0 sm:text-sm",
          @errors == [] && "border-secondary-300 focus:border-primary-400",
          @errors != [] && "border-danger-400 focus:border-danger-400"
        ]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @spec input(assigns()) :: rendered()
  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id} class={@label_class} required={@rest[:required]}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-secondary-900 focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem]",
          @input_class,
          @errors == [] && "border-secondary-300 focus:border-primary-400",
          @errors != [] && "border-danger-400 focus:border-danger-400"
        ]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @spec input(assigns()) :: rendered()
  def input(%{type: "chat-input"} = assigns) do
    ~H"""
    <div>
      <.label for={@id} class={@label_class} required={@rest[:required]}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        rows="3"
        class="block w-full border-gray-300 rounded-lg shadow-sm py-3 px-3 resize-none focus:ring-0 focus:border-indigo-500 sm:text-sm"
        placeholder={@rest[:placeholder]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @spec input(assigns()) :: rendered()
  def input(%{type: "multi-select"} = assigns) do
    ~H"""
    <div>
      <.label for={@id} class={@label_class} required={@rest[:required]}>{@label}</.label>
      <div>
        <div
          class="mt-2 block w-full rounded-md border bg-white shadow-sm focus:ring-0 sm:text-sm"
          phx-update="ignore"
          id={"#{@id}-multi-select-container"}
        >
          <select
            id={@id}
            name={@name}
            class="hidden"
            multiple
            {@rest}
            phx-hook="MultiSelect"
            data-placeholder={@prompt || dgettext("general", "Choose options")}
          >
            <option :for={{label, value} <- @options} value={value} selected={value in (@value || [])}>
              {label}
            </option>
          </select>
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
      <.error :for={msg <- @errors} :if={@nested_input?} class="flex items-center">
        <span>{msg}</span>
        <button
          type="button"
          class="ml-2 text-sm text-primary-600 hover:text-primary-500"
          phx-click={show(@show_nested_input)}
        >
          {dgettext("general", "Add new")}
        </button>
      </.error>
      <div :if={@nested_input?} id={@show_nested_input} class="hidden mt-4">
        {render_slot(@nested_input)}
      </div>
    </div>
    """
  end

  @spec input(assigns()) :: rendered()
  def input(assigns) do
    ~H"""
    <div>
      <.label for={@id} class={@label_class} required={@rest[:required]}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-secondary-900 focus:ring-0 sm:text-sm sm:leading-6",
          @input_class,
          @errors == [] && "border-secondary-300 focus:border-primary-400",
          @errors != [] && "border-danger-400 focus:border-danger-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :class, :string, default: "block text-sm font-semibold leading-6 text-secondary-800"
  attr :required, :boolean, default: false
  slot :inner_block, required: true

  @spec label(assigns()) :: rendered()
  def label(assigns) do
    ~H"""
    <label for={@for} class={@class}>
      {render_slot(@inner_block)}<span :if={@required} class="text-danger-600"> * </span>
    </label>
    """
  end
end
