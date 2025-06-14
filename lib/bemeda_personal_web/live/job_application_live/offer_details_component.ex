defmodule BemedaPersonalWeb.JobApplicationLive.OfferDetailsComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobOffers
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.I18n
  alias BemedaPersonalWeb.SharedHelpers
  alias Ecto.Multi

  @transition_attrs %{
    "notes" => "Offer extended with contract",
    "to_state" => "offer_extended"
  }

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <div class="flex items-center gap-2">
          <.icon name="hero-briefcase" class="w-6 h-6 text-indigo-600" />
          {dgettext("jobs", "Complete Offer Details")}
        </div>
        <:subtitle>
          {dgettext("jobs", "Fill in the employment terms for %{name}",
            name: "#{@job_application.user.first_name} #{@job_application.user.last_name}"
          )}
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="offer-details-form"
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      >
        <div class="space-y-6">
          <.auto_populated_info_section form={@form} />
          <.employment_terms_section form={@form} job_posting_options={@job_posting_options} />
        </div>

        <:actions>
          <.button
            type="button"
            phx-click="cancel"
            phx-target={@myself}
            class="!bg-gray-500 hover:!bg-gray-600 !text-white"
          >
            {dgettext("jobs", "Cancel")}
          </.button>
          <.button type="submit" class="!bg-green-600 hover:!bg-green-700 !text-white">
            <.icon name="hero-paper-airplane" class="w-4 h-4 mr-2" />
            {dgettext("jobs", "Send Contract")}
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp auto_populated_info_section(assigns) do
    ~H"""
    <div class="bg-gray-50 p-4 rounded-lg">
      <h3 class="font-semibold text-gray-900 mb-3">
        {dgettext("jobs", "Auto-populated Information")}
      </h3>
      <div class="grid grid-cols-2 gap-4 text-sm">
        <.info_item
          label={dgettext("jobs", "Candidate:")}
          value={"#{get_variable(@form, "First_Name")} #{get_variable(@form, "Last_Name")}"}
        />
        <.info_item label={dgettext("jobs", "Position:")} value={get_variable(@form, "Job_Title")} />
        <.info_item
          label={dgettext("jobs", "Company:")}
          value={get_variable(@form, "Client_Company")}
        />
        <.info_item
          label={dgettext("jobs", "Location:")}
          value={get_variable(@form, "Work_Location")}
        />
      </div>
    </div>
    """
  end

  defp info_item(assigns) do
    ~H"""
    <div>
      <span class="font-medium text-gray-700">{@label}</span>
      <span class="ml-2">{@value}</span>
    </div>
    """
  end

  defp employment_terms_section(assigns) do
    ~H"""
    <div class="border-t pt-4">
      <h3 class="font-semibold text-gray-900 mb-3">
        {dgettext("jobs", "Employment Terms")}
      </h3>

      <.job_posting_based_section
        :if={has_job_posting_options?(@job_posting_options)}
        form={@form}
        job_posting_options={@job_posting_options}
      />

      <div class="grid grid-cols-2 gap-4">
        <.input
          id="job_offer_start_date"
          label={dgettext("jobs", "Start Date")}
          name="job_offer[variables][Start_Date]"
          phx-debounce="500"
          type="date"
          value={get_variable(@form, "Start_Date")}
        />
        <.input
          id="job_offer_gross_salary"
          label={dgettext("jobs", "Gross Salary")}
          name="job_offer[variables][Gross_Salary]"
          phx-debounce="500"
          placeholder={
            salary_placeholder(@job_posting_options.salary_range, @job_posting_options.currency)
          }
          type="text"
          value={get_variable(@form, "Gross_Salary")}
        />
        <.input
          id="job_offer_working_hours"
          label={dgettext("jobs", "Working Hours per Week")}
          name="job_offer[variables][Working_Hours]"
          phx-debounce="500"
          placeholder="e.g., 40 hours"
          type="text"
          value={get_variable(@form, "Working_Hours")}
        />
        <.input
          id="job_offer_deadline"
          label={dgettext("jobs", "Offer Deadline")}
          name="job_offer[variables][Offer_Deadline]"
          phx-debounce="500"
          type="date"
          value={get_variable(@form, "Offer_Deadline")}
        />
        <.input
          id="job_offer_recruiter_phone"
          label={dgettext("jobs", "Recruiter Phone")}
          name="job_offer[variables][Recruiter_Phone]"
          phx-debounce="500"
          type="text"
          value={get_variable(@form, "Recruiter_Phone")}
        />
        <.input
          id="job_offer_recruiter_position"
          label={dgettext("jobs", "Recruiter Position")}
          name="job_offer[variables][Recruiter_Position]"
          phx-debounce="500"
          type="text"
          value={get_variable(@form, "Recruiter_Position")}
        />
      </div>
    </div>
    """
  end

  defp job_posting_based_section(assigns) do
    ~H"""
    <div class="bg-gray-50 p-4 rounded-lg mb-4">
      <h4 class="font-medium text-gray-700 mb-2">
        {dgettext("jobs", "Based on Job Posting")}
      </h4>
      <div class="grid grid-cols-2 gap-4">
        <div :if={@job_posting_options.workload_options != []}>
          <.input
            id="job_offer_workload"
            label={dgettext("jobs", "Workload")}
            name="job_offer[variables][Workload]"
            options={@job_posting_options.workload_options}
            prompt={dgettext("jobs", "Select workload")}
            type="select"
            value={get_variable(@form, "Workload")}
          />
        </div>
      </div>
      <div :if={@job_posting_options.salary_range} class="mt-2">
        <p class="text-sm text-gray-600">
          <span class="font-medium">{dgettext("jobs", "Posted salary range:")}</span>
          {@job_posting_options.salary_range}
        </p>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{job_application: job_application} = assigns, socket) do
    variables = JobOffers.auto_populate_variables(job_application)
    job_posting_options = get_ui_options(job_application.job_posting)

    job_offer_struct = %JobOffers.JobOffer{
      job_application_id: job_application.id,
      status: :pending,
      variables: variables
    }

    changeset = JobOffers.JobOffer.changeset(job_offer_struct, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))
     |> assign(:job_offer, job_offer_struct)
     |> assign(:job_posting_options, job_posting_options)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_offer" => offer_params}, socket) do
    # Update the job_offer struct with the new parameters
    updated_job_offer =
      Map.put(
        socket.assigns.job_offer,
        :variables,
        merge_variables(socket.assigns.job_offer.variables, offer_params["variables"])
      )

    changeset =
      updated_job_offer
      |> JobOffers.JobOffer.changeset(offer_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:job_offer, updated_job_offer)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("submit", %{"job_offer" => offer_params}, socket) do
    job_application = socket.assigns.job_application

    final_variables =
      merge_variables(socket.assigns.form.data.variables, offer_params["variables"])

    case create_offer_transaction(job_application, final_variables, socket.assigns.current_user) do
      {:ok, %{update_status: updated_job_application, create_offer: job_offer}} ->
        handle_successful_offer(socket, updated_job_application, job_offer)

      {:error, _operation, _value, _changes} ->
        handle_failed_offer(socket)
    end
  end

  def handle_event("cancel", _params, socket) do
    send(self(), :offer_cancelled)
    {:noreply, socket}
  end

  defp get_variable(form, key) do
    get_in(form.data.variables, [key])
  end

  defp has_job_posting_options?(job_posting_options) do
    job_posting_options.workload_options != [] or job_posting_options.salary_range
  end

  defp salary_placeholder(nil, currency), do: default_salary_placeholder(currency)

  defp salary_placeholder(range, currency) when is_binary(range) do
    case Regex.run(~r/(\d+)/, range) do
      [_full_match, first_num] ->
        dgettext("jobs", "e.g., %{amount} %{currency}",
          amount: first_num,
          currency: currency || "USD"
        )

      _no_match ->
        default_salary_placeholder(currency)
    end
  end

  defp salary_placeholder(_other, currency), do: default_salary_placeholder(currency)

  defp default_salary_placeholder(currency) do
    dgettext("jobs", "e.g., 85000 %{currency}", currency: currency || "CHF")
  end

  defp merge_variables(current_variables, manual_variables) do
    Map.merge(current_variables || %{}, manual_variables || %{})
  end

  defp create_offer_transaction(job_application, final_variables, current_user) do
    Multi.new()
    |> Multi.run(:update_status, fn _repo, _changes ->
      JobApplications.update_job_application_status(
        job_application,
        current_user,
        @transition_attrs
      )
    end)
    |> Multi.run(:create_offer, fn _repo, _changes ->
      JobOffers.create_job_offer(%{
        job_application_id: job_application.id,
        status: :pending,
        variables: final_variables
      })
    end)
    |> Multi.run(:generate_pdf, fn _repo, %{create_offer: job_offer} ->
      %{job_offer_id: job_offer.id}
      |> JobOffers.GenerateContract.new()
      |> Oban.insert()
    end)
    |> Repo.transaction()
  end

  defp handle_successful_offer(socket, updated_job_application, job_offer) do
    enqueue_status_update_notification(updated_job_application)
    send(self(), {:offer_submitted, job_offer})

    {:noreply,
     put_flash(
       socket,
       :info,
       dgettext("jobs", "Offer extended successfully. Contract is being generated.")
     )}
  end

  defp handle_failed_offer(socket) do
    {:noreply, put_flash(socket, :error, dgettext("jobs", "Failed to extend offer."))}
  end

  defp enqueue_status_update_notification(updated_job_application) do
    SharedHelpers.enqueue_email_notification_job(%{
      job_application_id: updated_job_application.id,
      type: "job_application_status_update",
      url:
        url(
          ~p"/jobs/#{updated_job_application.job_posting_id}/job_applications/#{updated_job_application.id}"
        )
    })
  end

  defp get_ui_options(job_posting) do
    %{
      workload_options: format_enum_options(job_posting.workload, &I18n.translate_workload/1),
      department_options:
        format_enum_options(job_posting.department, &I18n.translate_department/1),
      salary_range:
        format_salary_range(job_posting.salary_min, job_posting.salary_max, job_posting.currency),
      currency: job_posting.currency
    }
  end

  defp format_enum_options(nil, _translator), do: []

  defp format_enum_options(enum_list, translator) when is_list(enum_list) do
    Enum.map(enum_list, &format_enum_option(&1, translator))
  end

  defp format_enum_options(enum_value, translator) when is_atom(enum_value) do
    option_string = to_string(enum_value)
    translated = translator.(option_string)
    [{translated, option_string}]
  end

  defp format_enum_options(_other, _translator), do: []

  defp format_enum_option(option, translator) do
    option_string = to_string(option)
    translated = translator.(option_string)
    {translated, option_string}
  end

  defp format_salary_range(nil, nil, _currency), do: nil

  defp format_salary_range(min, max, currency) when is_integer(min) and is_integer(max) do
    "#{min} - #{max} #{currency}"
  end

  defp format_salary_range(min, nil, currency) when is_integer(min) do
    "#{dgettext("jobs", "From")} #{min} #{currency}"
  end

  defp format_salary_range(nil, max, currency) when is_integer(max) do
    "#{dgettext("jobs", "Up to")} #{max} #{currency}"
  end
end
