defmodule BemedaPersonalWeb.CompanyPublicLive.Jobs do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    case get_company(id) do
      {:ok, company} ->
        job_postings = Jobs.list_job_postings(%{company_id: company.id}, 100)

        {:ok,
         socket
         |> assign(:page_title, "#{company.name} - Jobs")
         |> assign(:company, company)
         |> assign(:job_postings, job_postings)}

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
end
