defmodule BemedaPersonalWeb.SharedHelpers do
  @moduledoc false

  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  alias BemedaPersonalWeb.JobListComponent

  @spec to_html(binary()) :: Phoenix.HTML.safe()
  def to_html(markdown) do
    markdown
    |> MDEx.to_html!(
      features: [syntax_highlight_theme: "onedark"],
      extension: [
        strikethrough: true,
        underline: true,
        tagfilter: true,
        table: true,
        autolink: true,
        tasklist: true,
        footnotes: true,
        shortcodes: true
      ],
      parse: [
        smart: true,
        relaxed_tasklist_matching: true,
        relaxed_autolinks: true
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
end
