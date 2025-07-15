defmodule BemedaPersonalWeb.Components.Core.NavigationDrawer do
  @moduledoc """
  Mobile navigation drawer component matching Figma design.
  """

  use BemedaPersonalWeb, :verified_routes
  use Gettext, backend: BemedaPersonalWeb.Gettext
  use Phoenix.Component

  import BemedaPersonalWeb.Components.Core.Typography

  alias Phoenix.LiveView.JS

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  defp icon_path("icon-bell"), do: ~p"/images/icons/icon-bell.svg"
  defp icon_path("icon-briefcase"), do: ~p"/images/icons/icon-briefcase.svg"
  defp icon_path("icon-building"), do: ~p"/images/icons/icon-building.svg"
  defp icon_path("icon-calendar"), do: ~p"/images/icons/icon-calendar.svg"
  defp icon_path("icon-cash"), do: ~p"/images/icons/icon-cash.svg"
  defp icon_path("icon-cog"), do: ~p"/images/icons/icon-cog.svg"
  defp icon_path("icon-key"), do: ~p"/images/icons/icon-key.svg"
  defp icon_path("icon-logout"), do: ~p"/images/icons/icon-logout.svg"
  defp icon_path("icon-user"), do: ~p"/images/icons/icon-user.svg"
  defp icon_path("icon-user-group"), do: ~p"/images/icons/icon-user-group.svg"
  defp icon_path("icon-video-camera"), do: ~p"/images/icons/icon-video-camera.svg"

  @doc """
  Renders a mobile navigation drawer.
  """
  attr :id, :string, default: "mobile-nav-drawer"
  attr :current_user, :map, required: true
  attr :current_path, :string, required: true
  attr :user_company, :map, default: nil

  @spec drawer(assigns()) :: rendered()
  def drawer(assigns) do
    ~H"""
    <div id={@id} class="lg:hidden">
      <div
        id={"#{@id}-backdrop"}
        class="fixed inset-0 bg-black bg-opacity-50 z-40 hidden"
        phx-click={hide_drawer(@id)}
      />

      <div
        id={"#{@id}-panel"}
        class="fixed left-0 top-0 h-full w-full sm:w-[430px] max-w-full bg-white z-50 transform -translate-x-full transition-transform duration-300 ease-in-out"
        style="transform: translateX(-100%)"
      >
        <div class="flex flex-col h-full">
          <.drawer_header id={@id} />
          <.drawer_user_profile current_user={@current_user} />
          <.drawer_menu
            current_user={@current_user}
            current_path={@current_path}
            user_company={@user_company}
          />
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true

  defp drawer_header(assigns) do
    ~H"""
    <div class="flex items-center justify-between px-4 py-2.5 border-b border-strokes">
      <div class="flex items-center gap-2">
        <img src={~p"/images/logo-bemeda.svg"} alt="Bemeda Logo" class="h-[38.81px] w-[35.502px]" />
        <span class="text-primary-500 text-[18px] font-semibold tracking-[0.027px]">
          Bemeda Personal
        </span>
      </div>
      <button type="button" phx-click={hide_drawer(@id)} class="p-0">
        <img src={~p"/images/icons/icon-x-close.svg"} alt={gettext("Close")} class="w-4 h-4" />
      </button>
    </div>
    """
  end

  attr :current_user, :map, required: true

  defp drawer_user_profile(assigns) do
    ~H"""
    <div class="px-4 py-3">
      <div class="flex items-center justify-between p-2 border border-strokes rounded-lg">
        <div class="flex items-center gap-2">
          <div class="w-9 h-9 bg-gray-300 rounded-full overflow-hidden flex items-center justify-center">
            <img
              src={~p"/images/icons/avatar-placeholder.svg"}
              alt={gettext("User avatar")}
              class="w-full h-full"
            />
          </div>
          <div>
            <.text class="text-gray-700 font-medium">
              {[@current_user.first_name, @current_user.last_name]
              |> Enum.filter(& &1)
              |> Enum.join(" ")
              |> String.trim()}
            </.text>
            <.caption class="text-gray-300">
              {if @current_user.user_type == :employer,
                do: gettext("Medical organization"),
                else: gettext("Job seeker")}
            </.caption>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :current_user, :map, required: true
  attr :current_path, :string, required: true
  attr :user_company, :map, default: nil

  defp drawer_menu(assigns) do
    ~H"""
    <nav class="flex-1 overflow-y-auto px-4 py-2">
      <div class="space-y-1">
        <.menu_item
          :if={@current_user.user_type == :employer && @user_company}
          label={gettext("Company Dashboard")}
          icon="icon-building"
          path={~p"/company"}
          current_path={@current_path}
        />

        <.menu_section
          :if={@current_user.user_type == :employer}
          title={gettext("Jobs")}
          icon="icon-briefcase"
          items={[
            %{label: gettext("Post a job"), path: ~p"/company/jobs/new"},
            %{label: gettext("View all jobs"), path: ~p"/company/jobs"}
          ]}
          current_path={@current_path}
        />

        <.menu_section
          :if={@current_user.user_type == :job_seeker}
          title={gettext("Find Jobs")}
          icon="icon-briefcase"
          items={[
            %{label: gettext("Browse Jobs"), path: ~p"/jobs"},
            %{label: gettext("My Applications"), path: ~p"/job_applications"}
          ]}
          current_path={@current_path}
        />

        <.menu_item
          :if={@current_user.user_type == :job_seeker}
          label={gettext("My Resume")}
          icon="icon-user"
          path={~p"/resume"}
          current_path={@current_path}
        />

        <.menu_item
          label={gettext("Notifications")}
          icon="icon-bell"
          path={~p"/notifications"}
          current_path={@current_path}
        />

        <div class="border-b border-strokes my-2" />

        <.menu_item
          label={gettext("Account Settings")}
          icon="icon-cog"
          path={~p"/users/settings"}
          current_path={@current_path}
        />

        <.menu_item
          label={gettext("Sign out")}
          icon="icon-logout"
          path={~p"/users/log_out"}
          method="delete"
          current_path={@current_path}
        />
      </div>
    </nav>
    """
  end

  attr :title, :string, required: true
  attr :icon, :string, required: true
  attr :items, :list, required: true
  attr :current_path, :string, required: true

  defp menu_section(assigns) do
    ~H"""
    <div class="py-1">
      <button
        type="button"
        class="w-full flex items-center justify-between p-2 rounded hover:bg-gray-50"
        phx-click={toggle_section(@title)}
      >
        <div class="flex items-center gap-3">
          <img src={icon_path(@icon)} alt="" class="w-5 h-5" />
          <span class="text-[14px] text-neutral-500">{@title}</span>
        </div>
        <img
          src={~p"/images/icons/icon-chevron-down.svg"}
          alt=""
          class="w-4 h-4 transition-transform"
          id={"#{@title}-chevron"}
        />
      </button>
      <div id={"#{@title}-items"} class="hidden pl-8 space-y-1">
        <.link
          :for={item <- @items}
          navigate={item.path}
          phx-click={hide_drawer("mobile-nav-drawer")}
          class={[
            "block p-2 text-[14px] rounded hover:bg-gray-50",
            @current_path == item.path && "bg-primary-50 text-primary-600"
          ]}
        >
          {item.label}
        </.link>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :path, :string, required: true
  attr :current_path, :string, required: true
  attr :method, :string, default: nil

  defp menu_item(assigns) do
    ~H"""
    <.link
      navigate={!@method && @path}
      href={@method && @path}
      method={@method}
      phx-click={hide_drawer("mobile-nav-drawer")}
      class={[
        "flex items-center gap-3 p-2 rounded hover:bg-gray-50",
        @current_path == @path && "bg-primary-50"
      ]}
    >
      <img src={icon_path(@icon)} alt="" class="w-5 h-5" />
      <span class={[
        "text-[14px]",
        (@current_path == @path && "text-primary-600") || "text-neutral-500"
      ]}>
        {@label}
      </span>
    </.link>
    """
  end

  @doc """
  Shows the navigation drawer.
  """
  @spec show_drawer(String.t()) :: JS.t()
  def show_drawer(id) do
    %JS{}
    |> JS.show(to: "##{id}-backdrop")
    |> JS.remove_class("hidden", to: "##{id}-panel")
    |> JS.set_attribute({"style", ""}, to: "##{id}-panel")
    |> JS.transition(
      {"transform transition-transform duration-300 ease-in-out", "-translate-x-full",
       "translate-x-0"},
      to: "##{id}-panel"
    )
    |> JS.add_class("overflow-hidden", to: "body")
  end

  @doc """
  Hides the navigation drawer.
  """
  @spec hide_drawer(String.t()) :: JS.t()
  def hide_drawer(id) do
    %JS{}
    |> JS.transition(
      {"transform transition-transform duration-300 ease-in-out", "translate-x-0",
       "-translate-x-full"},
      to: "##{id}-panel"
    )
    |> JS.hide(
      to: "##{id}-backdrop",
      transition: {"transition-opacity duration-300", "opacity-100", "opacity-0"}
    )
    |> JS.remove_class("overflow-hidden", to: "body")
  end

  defp toggle_section(title) do
    %JS{}
    |> JS.toggle(to: "##{title}-items")
    |> JS.toggle_class("rotate-180", to: "##{title}-chevron")
  end
end
