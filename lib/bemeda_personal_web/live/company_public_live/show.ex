defmodule BemedaPersonalWeb.CompanyPublicLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    case get_company(id) do
      {:ok, company} ->
        job_count = get_job_count(company.id)

        {:ok,
         socket
         |> assign(:page_title, company.name)
         |> assign(:company, company)
         |> assign(:job_count, job_count)}

      {:error, _reason} ->
        {:ok,
         socket
         |> put_flash(:error, "Company not found")
         |> redirect(to: ~p"/")}
    end
  end

  defp get_company(id) do
    try do
      company = Companies.get_company!(id)
      {:ok, company}
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end

  defp get_job_count(company_id) do
    Jobs.list_job_postings(%{company_id: company_id})
    |> length()
  end
end
