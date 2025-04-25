defmodule BemedaPersonalWeb.SharedHelpers do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.MuxHelpers.Client, as: MuxClient, warn: false
  alias BemedaPersonal.S3Helper.Client
  alias BemedaPersonalWeb.Endpoint

  require Logger

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

    if Phoenix.LiveView.connected?(socket) do
      Phoenix.PubSub.subscribe(
        BemedaPersonal.PubSub,
        "job_posting_assets_#{job_posting.id}"
      )
    end

    {:noreply,
     socket
     |> assign(:job_posting, job_posting)
     |> assign(:page_title, job_posting.title)
     |> assign_current_user_application()}
  end

  @spec reassign_job_posting(Phoenix.LiveView.Socket.t(), map()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def reassign_job_posting(socket, %{media_asset_updated: _media_asset, job_posting: job_posting}) do
    {:noreply, assign(socket, :job_posting, job_posting)}
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

  @spec create_video_upload(Phoenix.LiveView.Socket.t(), map()) ::
          {:reply, map(), Phoenix.LiveView.Socket.t()}
  def create_video_upload(socket, params) do
    upload_id = Ecto.UUID.generate()

    case Client.get_presigned_url(upload_id, :put) do
      {:ok, upload_url} ->
        {:reply, %{upload_url: upload_url, upload_id: upload_id},
         socket
         |> assign(:enable_submit?, false)
         |> assign(:media_data, %{file_name: params["filename"], upload_id: upload_id})}

      {:error, reason} ->
        Logger.error("Failed to get presigned URL for upload: #{inspect(reason)}")
        {:reply, %{error: "Failed to create upload"}, socket}
    end
  end

  @spec upload_video_to_mux(Phoenix.LiveView.Socket.t(), map()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def upload_video_to_mux(socket, params) do
    upload_id = Ecto.UUID.cast!(params["upload_id"])

    case Client.get_presigned_url(upload_id, :get) do
      {:ok, file_url} ->
        options = %{cors_origin: Endpoint.url(), input: file_url, playback_policy: "public"}
        client = Mux.client()
        create_asset(client, options, socket)

      {:error, reason} ->
        Logger.error("Failed to get presigned URL for video: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  defp create_asset(client, options, socket) do
    case MuxClient.create_asset(client, options) do
      {:ok, mux_asset, _client} ->
        {:noreply,
         socket
         |> assign(:enable_submit?, true)
         |> assign(
           :media_data,
           Map.merge(socket.assigns.media_data, %{
             asset_id: mux_asset["id"]
           })
         )}

      response ->
        Logger.error(
          "message.additional_processing: " <>
            inspect(response)
        )

        {:noreply, socket}
    end
  end

  @spec update_mux_data(map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def update_mux_data(mux_data, socket) do
    if socket.assigns[:mux_data] && socket.assigns.mux_data[:asset_id] == mux_data[:asset_id] do
      {:ok,
       socket
       |> assign(:enable_submit?, true)
       |> assign(:mux_data, Map.merge(socket.assigns.mux_data, mux_data))
       |> Phoenix.LiveView.push_event("video_upload_completed", %{})}
    else
      {:ok, socket}
    end
  end

  @spec get_presigned_url(String.t()) :: String.t()
  def get_presigned_url(upload_id) do
    {:ok, url} = Client.get_presigned_url(upload_id, :get)
    url
  end
end
