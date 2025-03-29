defmodule BemedaPersonalWeb.SharedHelpers do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView

  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobListComponent

  @spec to_html(binary()) :: Phoenix.HTML.safe()
  def to_html(markdown) do
    markdown
    |> MDEx.to_html!(
      features: [syntax_highlight_theme: "onedark"],
      extension: [
        autolink: true,
        footnotes: true,
        shortcodes: true,
        strikethrough: true,
        table: true,
        tagfilter: true,
        tasklist: true,
        underline: true
      ],
      parse: [
        relaxed_autolinks: true,
        relaxed_tasklist_matching: true,
        smart: true
      ],
      render: [
        github_pre_lang: true,
        escape: true
      ]
    )
    |> Phoenix.HTML.raw()
  end

  @spec process_job_filters(map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def process_job_filters(filter_params, socket) do
    filters =
      filter_params
      |> Enum.filter(fn {_k, v} -> v && v != "" end)
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Enum.into(%{})
      |> Map.merge(socket.assigns.filters)

    send_update(JobListComponent, id: "job-post-list", filters: filters)

    {:noreply, assign(socket, :filters, filters)}
  end

  @spec assign_job_posting(Phoenix.LiveView.Socket.t(), String.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def assign_job_posting(socket, job_id) do
    job_posting = Jobs.get_job_posting!(job_id)

    {:noreply,
     socket
     |> assign(:job_posting, job_posting)
     |> assign(:page_title, job_posting.title)
     |> assign_current_user_application()}
  end

  defp assign_current_user_application(socket) do
    if socket.assigns.current_user do
      assign(
        socket,
        :application,
        Jobs.get_user_job_application(
          socket.assigns.current_user,
          socket.assigns.job_posting
        )
      )
    else
      assign(socket, :application, nil)
    end
  end
end
