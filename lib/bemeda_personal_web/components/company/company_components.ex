defmodule BemedaPersonalWeb.Components.Company.CompanyComponents do
  @moduledoc """
  Reusable company-related components for displaying company information
  across the application.
  """

  use BemedaPersonalWeb, :html

  alias BemedaPersonalWeb.Components.Shared.CardComponent
  alias BemedaPersonalWeb.Components.Shared.DetailItemComponent
  alias BemedaPersonalWeb.Components.Shared.PageHeaderComponent

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :active_page, :string, default: nil
  attr :company, :any, required: true

  @spec breadcrumb(assigns()) :: output()
  def breadcrumb(assigns) do
    assigns =
      assign(assigns, :items, [
        %{text: assigns.company.name, link: ~p"/company/#{assigns.company.id}"}
      ])

    ~H"""
    <PageHeaderComponent.breadcrumb items={@items} active_page={@active_page} />
    """
  end

  attr :company, :any, required: true
  attr :show_links, :boolean, default: true

  @spec details_card(assigns()) :: output()
  def details_card(assigns) do
    ~H"""
    <CardComponent.card>
      <:header>
        <h2 class="text-lg font-medium text-gray-900">
          {dgettext("companies", "About the Company")}
        </h2>
      </:header>
      <:body>
        <DetailItemComponent.detail_grid>
          <DetailItemComponent.detail_item
            label={dgettext("companies", "Company Name")}
            value={@company.name}
            link={~p"/company/#{@company.id}"}
          />

          <DetailItemComponent.detail_item
            :if={@company.industry}
            label={dgettext("companies", "Industry")}
            value={@company.industry}
          />

          <DetailItemComponent.detail_item
            :if={@company.size}
            label={dgettext("companies", "Company Size")}
            value={@company.size}
          />

          <DetailItemComponent.detail_item
            :if={@company.website_url}
            label={dgettext("companies", "Website")}
            value={@company.website_url}
            link={@company.website_url}
            external_link={true}
          />
        </DetailItemComponent.detail_grid>
      </:body>
      <:actions :if={@show_links}>
        <.link
          navigate={~p"/company/#{@company.id}"}
          class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          {dgettext("companies", "View Company Profile")}
        </.link>
        <.link
          navigate={~p"/company/#{@company.id}/jobs"}
          class="ml-3 inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          {dgettext("companies", "View All Jobs")}
        </.link>
      </:actions>
    </CardComponent.card>
    """
  end

  attr :company, :any, required: true
  attr :show_website_button, :boolean, default: true

  @spec header(assigns()) :: output()
  def header(assigns) do
    assigns =
      assign(
        assigns,
        :subtitle,
        "#{assigns.company.industry} • #{assigns.company.location || dgettext("companies", "Remote")}"
      )

    ~H"""
    <PageHeaderComponent.page_header title={@company.name} subtitle={@subtitle}>
      <:actions>
        <a
          :if={@company.website_url && @show_website_button}
          href={@company.website_url}
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          {dgettext("companies", "Visit Website")}
        </a>
      </:actions>
    </PageHeaderComponent.page_header>
    """
  end
end
