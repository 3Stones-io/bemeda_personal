defmodule BemedaPersonalWeb.SharedHelpers do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.MuxHelpers.Client
  alias BemedaPersonal.MuxHelpers.WebhookHandler

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

  @spec create_video_upload(Phoenix.LiveView.Socket.t(), String.t(), pid()) ::
          {:reply, map(), Phoenix.LiveView.Socket.t()}
  def create_video_upload(socket, filename, pid) do
    with {:ok, upload_url, upload_id} <- Client.create_direct_upload(),
         {:ok, _pid} <- WebhookHandler.register(upload_id, pid) do
      {:reply, %{upload_url: upload_url},
       socket
       |> assign(:enable_submit?, false)
       |> assign(:mux_data, %{file_name: filename})}
    else
      {:error, _reason} ->
        {:reply, %{error: "Failed to create upload URL"}, socket}
    end
  end
end
