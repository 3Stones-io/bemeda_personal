defmodule BemedaPersonalWeb.Storybook do
  @moduledoc """
  Configuration module for Phoenix Storybook.

  This module sets up the Storybook integration for the Bemeda Personal design system,
  configuring paths for content, CSS, and JavaScript assets.
  """

  use PhoenixStorybook,
    otp_app: :bemeda_personal,
    content_path: Path.expand("./storybook", __DIR__),
    css_path: "/assets/app.css",
    js_path: "/assets/storybook.js",
    title: "Bemeda Personal Design System"
end
