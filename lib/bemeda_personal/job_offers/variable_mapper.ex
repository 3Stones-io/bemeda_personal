defmodule BemedaPersonal.JobOffers.VariableMapper do
  @moduledoc """
  Maps job application data to template variables
  """

  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.I18n

  @type job_application :: JobApplication.t()
  @type job_posting :: JobPosting.t()
  @type template_variables :: %{String.t() => String.t()}

  @spec auto_populate_variables(job_application()) :: template_variables()
  def auto_populate_variables(job_application) do
    job_application = Repo.preload(job_application, [:user, job_posting: [company: :admin_user]])

    contract_locale = determine_contract_locale(job_application)

    Gettext.with_locale(BemedaPersonalWeb.Gettext, contract_locale, fn ->
      %{}
      |> Map.merge(map_company_variables(job_application.job_posting.company))
      |> Map.merge(map_job_posting_variables(job_application.job_posting))
      |> Map.merge(map_job_seeker_variables(job_application.user))
      |> Map.merge(map_manual_fields())
      |> Map.merge(map_system_variables(job_application.user))
    end)
  end

  defp map_company_variables(company) do
    %{
      "Client_Company" => company.name,
      "Employer_Country" => company.location || "",
      "Recruiter_Email" => company.admin_user.email,
      "Recruiter_Name" => "#{company.admin_user.first_name} #{company.admin_user.last_name}"
    }
  end

  defp map_job_posting_variables(job_posting) do
    workload = format_workload(job_posting.workload)
    contract_type = format_employment_type(job_posting.employment_type)

    %{
      "Contract_Type" => contract_type,
      "Job_Title" => job_posting.title,
      "Work_Location" => job_posting.location || "",
      "Workload" => workload
    }
  end

  defp map_job_seeker_variables(user) do
    title =
      case user.gender do
        :male ->
          I18n.translate_title("male")

        :female ->
          I18n.translate_title("female")

        nil ->
          ""
      end

    %{
      "Candidate_Full_Name" => "#{user.first_name} #{user.last_name}",
      "City" => user.city || "",
      "First_Name" => user.first_name,
      "Last_Name" => user.last_name,
      "Salutation" => title,
      "Street" => user.street || "",
      "Title" => title,
      "ZipCode" => user.zip_code || ""
    }
  end

  defp map_manual_fields do
    %{
      "Gross_Salary" => "",
      "Offer_Deadline" => "",
      "Recruiter_Phone" => "",
      "Recruiter_Position" => "",
      "Start_Date" => "",
      "Working_Hours" => ""
    }
  end

  defp map_system_variables(user) do
    current_date = Date.utc_today()
    serial_number = "JO-#{current_date.year}-#{:rand.uniform(999_999)}"
    formatted_date = format_date_for_contract(current_date, user.city)

    %{
      "Date" => Date.to_string(current_date),
      "Place_Date" => formatted_date,
      "Signature" => "{{signature}}",
      "Serial_Number" => serial_number
    }
  end

  defp format_date_for_contract(date, city) do
    # Format date as "Place, Date" for contract signature section
    # Example: "Zurich, 23rd June 2025"
    day = date.day
    month_name = get_month_name(date.month)
    year = date.year

    # Add ordinal suffix to day
    day_with_suffix = add_ordinal_suffix(day)

    formatted_date = "#{day_with_suffix} #{month_name} #{year}"

    "#{city}, #{formatted_date}"
  end

  defp get_month_name(month) do
    months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ]

    Enum.at(months, month - 1)
  end

  defp add_ordinal_suffix(day) do
    case day do
      1 -> "1st"
      2 -> "2nd"
      3 -> "3rd"
      21 -> "21st"
      22 -> "22nd"
      23 -> "23rd"
      31 -> "31st"
      _other_day -> "#{day}th"
    end
  end

  defp determine_contract_locale(job_application) do
    job_seeker_locale = job_application.user.locale
    company_admin_locale = job_application.job_posting.company.admin_user.locale
    job_posting_languages = job_application.job_posting.language || []

    posting_locales = Enum.map(job_posting_languages, &language_to_locale/1)

    locale =
      cond do
        job_seeker_locale in posting_locales ->
          job_seeker_locale

        company_admin_locale in posting_locales ->
          company_admin_locale

        true ->
          job_seeker_locale
      end

    Atom.to_string(locale)
  end

  defp language_to_locale(language) do
    case language do
      :English -> :en
      :French -> :fr
      :German -> :de
      :Italian -> :it
    end
  end

  defp format_employment_type(nil), do: ""

  defp format_employment_type(employment_type) when is_atom(employment_type) do
    employment_type
    |> Atom.to_string()
    |> I18n.translate_employment_type()
  end

  defp format_workload(workload_list) when is_list(workload_list) do
    case workload_list do
      [] ->
        I18n.translate_workload("Full-time")

      workloads ->
        Enum.map_join(workloads, ", ", fn workload ->
          workload
          |> Atom.to_string()
          |> I18n.translate_workload()
        end)
    end
  end

  defp format_workload(nil) do
    I18n.translate_workload("Full-time")
  end

  defp format_workload(workload) when is_atom(workload) do
    workload
    |> Atom.to_string()
    |> I18n.translate_workload()
  end
end
