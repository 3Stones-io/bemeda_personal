defmodule BemedaPersonalWeb.Components.Core.EmailConfirmation do
  @moduledoc """
  Email confirmation component with illustration and resend functionality.
  Shows a beautiful confirmation screen with email illustration from Figma.
  """

  use BemedaPersonalWeb, :verified_routes
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type rendered :: Phoenix.LiveView.Rendered.t()

  attr :email, :string, required: true
  attr :resend_enabled, :boolean, default: false
  attr :resend_countdown, :integer, default: 0
  attr :on_resend, JS, default: %JS{}

  attr :illustration_url, :string, default: nil

  attr :class, :string, default: ""

  @spec email_confirmation(assigns()) :: rendered()
  def email_confirmation(assigns) do
    ~H"""
    <div class={["flex items-center justify-center min-h-screen px-4", @class]}>
      <div class="bg-white rounded-2xl px-4 py-8 w-full max-w-[398px]">
        <div class="flex flex-col gap-8 items-center justify-start">
          <div class="flex flex-col gap-6 items-center justify-start text-center w-full">
            <h2 class="font-medium text-[24px] leading-[33px] text-[#1f1f1f] w-full">
              You've got mail!
            </h2>
            <p class="font-normal text-[16px] leading-[24px] tracking-[0.024px] text-[#555555] w-full">
              We just sent you an activation link to verify your email address.
              Check your spam folder if you don't see it in your inbox.
            </p>
          </div>

          <div class="w-full">
            <div class="h-[334px] overflow-hidden relative w-[370px] mx-auto">
              <img
                src={@illustration_url || ~p"/images/onboarding/email-confirmation-illustration.svg"}
                alt="Email confirmation illustration"
                class="block w-full h-full object-contain"
              />
            </div>

            <button
              type="button"
              class="bg-[#7b4eab] text-white h-11 px-5 py-3 rounded-lg font-medium text-[16px] leading-[22px] tracking-[0.08px] w-full mt-2"
            >
              Open my email
            </button>
          </div>
        </div>

        <div class="flex flex-col gap-4 items-center justify-start mt-3 text-[14px] leading-[16px] tracking-[0.07px] text-center">
          <p class="text-[#555555]">
            Didn't receive any email?
          </p>
          <%= if @resend_enabled do %>
            <button type="button" class="text-[#7b4eab] font-medium" phx-click={@on_resend}>
              Resend
            </button>
          <% else %>
            <p class="text-[#555555]">
              Resend in {@resend_countdown} sec
            </p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
