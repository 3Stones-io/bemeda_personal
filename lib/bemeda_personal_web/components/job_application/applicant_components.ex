defmodule BemedaPersonalWeb.Components.JobApplication.ApplicantComponents do
  @moduledoc """
  Components for displaying and managing job applicants.
  """

  use BemedaPersonalWeb, :html

  alias BemedaPersonalWeb.Components.Company.RatingComponent
  alias BemedaPersonalWeb.Components.JobApplication.StatusComponent
  alias BemedaPersonalWeb.Components.Media.MediaComponents
  alias BemedaPersonalWeb.Components.Shared.ActionGroupComponent
  alias BemedaPersonalWeb.Components.Shared.CardComponent
  alias BemedaPersonalWeb.Components.Shared.DetailItemComponent
  alias BemedaPersonalWeb.Components.Shared.TagsInputComponent
  alias BemedaPersonalWeb.SharedHelpers

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :applicant, :any, required: true
  attr :current_user, :any, default: nil
  attr :id, :string, required: true
  attr :job, :any, required: true
  attr :show_job, :boolean, default: false
  attr :tag_limit, :integer, default: 3

  @spec applicant_card(assigns()) :: output()
  def applicant_card(assigns) do
    actions = [
      %{
        type: :chat,
        path:
          ~p"/jobs/#{assigns.applicant.job_posting_id}/job_applications/#{assigns.applicant.id}",
        title: dgettext("jobs", "Chat with applicant"),
        icon: "hero-chat-bubble-left-right",
        method: :navigate
      }
    ]

    assigns = assign(assigns, :actions, actions)

    ~H"""
    <div
      class="px-8 py-6 relative group cursor-pointer"
      phx-click={JS.navigate(~p"/companies/#{@job.company_id}/applicant/#{@applicant.id}")}
    >
      <div class="flex justify-between items-start">
        <div class="flex-1">
          <div class="flex items-center gap-3">
            <h3 class="text-lg font-medium text-gray-900">
              <.link navigate={~p"/companies/#{@job.company_id}/applicant/#{@applicant.id}"} id={@id}>
                {"#{@applicant.user.first_name} #{@applicant.user.last_name}"}
              </.link>
            </h3>

            <div class="relative">
              <StatusComponent.status_badge class="px-2.5 py-1" status={@applicant.state} />
            </div>
          </div>

          <div class="text-sm text-gray-500 mt-1">
            <p :if={@applicant.user.email}>
              <span class="inline-flex items-center">
                <.icon name="hero-envelope" class="w-4 h-4 mr-1" />
                {@applicant.user.email}
              </span>
            </p>
          </div>

          <div class="flex flex-wrap gap-2 mt-2">
            <div
              :for={tag <- @applicant.tags |> Enum.take(@tag_limit)}
              class="bg-blue-500 text-white px-3 py-1 text-xs rounded-full"
            >
              {tag.name}
            </div>
            <div
              :if={@applicant.tags && length(@applicant.tags) > @tag_limit}
              class="bg-gray-300 text-gray-700 px-3 py-1 text-xs rounded-full"
            >
              +{length(@applicant.tags) - @tag_limit} {dgettext("jobs", "more")}
            </div>
          </div>
        </div>

        <div>
          <div :if={@show_job && @job} class="text-sm text-end">
            <p class="font-medium text-gray-900">{@job.title}</p>
            <p class="text-gray-500">{@job.location || dgettext("jobs", "Remote")}</p>
          </div>
        </div>
      </div>

      <div class="absolute bottom-2 right-6 z-10">
        <ActionGroupComponent.circular_action_group actions={@actions} />
      </div>
    </div>
    """
  end

  attr :application, :any, required: true
  attr :company, :any, required: true
  attr :current_user, :any, required: true
  attr :job, :any, required: true
  attr :resume, :any, default: nil
  attr :show_actions, :boolean, default: false
  attr :tags_form, Phoenix.HTML.Form, required: true
  attr :target, :string, default: nil

  @spec applicant_detail(assigns()) :: output()
  def applicant_detail(assigns) do
    ~H"""
    <CardComponent.card class="mb-6">
      <:header>
        <div class="flex justify-between items-center">
          <div>
            <h2 class="text-xl font-semibold text-gray-900">
              {dgettext("jobs", "Application Information")}
            </h2>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">
              {dgettext("jobs", "Personal details and application.")}
            </p>
          </div>
          <.link
            navigate={~p"/jobs/#{@application.job_posting_id}/job_applications/#{@application.id}"}
            class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <.icon name="hero-chat-bubble-left-right" class="w-4 h-4 mr-2" /> {dgettext(
              "jobs",
              "Chat with Applicant"
            )}
          </.link>
        </div>
      </:header>
      <:body>
        <DetailItemComponent.detail_grid>
          <DetailItemComponent.detail_item
            label={dgettext("jobs", "Full name")}
            value={"#{@application.user.first_name} #{@application.user.last_name}"}
          />

          <DetailItemComponent.detail_item
            icon="hero-envelope"
            label={dgettext("jobs", "Email address")}
            value={@application.user.email}
          />

          <div class="px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Rating")}</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              <.live_component
                current_user={@current_user}
                entity_id={@application.user.id}
                entity_name={"#{@application.user.first_name} #{@application.user.last_name}"}
                entity_type="User"
                id={"rating-display-applicant-#{@application.user.id}"}
                module={RatingComponent}
                rater_id={@company.id}
                rater_type="Company"
              />
            </dd>
          </div>

          <DetailItemComponent.detail_item label={dgettext("jobs", "Applied for")} value={@job.title} />

          <DetailItemComponent.detail_item
            icon="hero-calendar"
            label={dgettext("jobs", "Applied on")}
            value={Calendar.strftime(@application.inserted_at, "%B %d, %Y")}
          />

          <div class="px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Tags")}</dt>
            <dd class="text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              <.form
                :let={f}
                for={@tags_form}
                phx-submit="update_tags"
                class="tags-input-form flex items-start gap-2"
              >
                <div class="flex-1">
                  <TagsInputComponent.tags_input>
                    <:hidden_input>
                      <.input
                        field={f[:tags]}
                        type="hidden"
                        value={Enum.map_join(@application.tags, ",", & &1.name)}
                        id="application-tags-input"
                      />
                    </:hidden_input>
                  </TagsInputComponent.tags_input>
                </div>

                <button
                  type="submit"
                  class={[
                    "inline-flex items-center justify-center px-2 py-1 border border-transparent min-w-[100px] h-[42px]",
                    "text-xs font-medium rounded-md shadow-sm text-white bg-indigo-600",
                    "hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  ]}
                >
                  {dgettext("jobs", "Update Tags")}
                </button>
              </.form>
            </dd>
          </div>

          <div class="px-4 py-5 bg-gray-50 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Cover letter")}</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0 prose max-w-none">
              <div class="md-to-html">
                {SharedHelpers.to_html(@application.cover_letter)}
              </div>
            </dd>
          </div>
        </DetailItemComponent.detail_grid>

        <MediaComponents.video_player media_asset={@application.media_asset} />
      </:body>
    </CardComponent.card>

    <CardComponent.card :if={@resume}>
      <:header>
        <h2 class="text-xl font-semibold text-gray-900">{dgettext("jobs", "Resume Information")}</h2>
        <p class="mt-1 max-w-2xl text-sm text-gray-500">
          {dgettext("jobs", "Applicant's resume details")}
        </p>
      </:header>
      <:body>
        <DetailItemComponent.detail_grid>
          <div class="px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">{dgettext("jobs", "Resume")}</dt>
            <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">
              <div :if={@resume.is_public}>
                <.link
                  navigate={~p"/resumes/#{@resume.id}"}
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  <.icon name="hero-document-text" class="w-4 h-4 mr-2" /> {dgettext(
                    "jobs",
                    "View Resume"
                  )}
                </.link>
              </div>
              <div :if={!@resume.is_public} class="text-gray-500 italic">
                {dgettext("jobs", "Resume is not publicly available")}
              </div>
            </dd>
          </div>
        </DetailItemComponent.detail_grid>
      </:body>
    </CardComponent.card>
    """
  end
end
