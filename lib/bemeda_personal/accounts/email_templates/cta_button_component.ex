defmodule BemedaPersonal.Accounts.EmailTemplates.CtaButtonComponent do
  use MjmlEEx.Component, mode: :runtime

  @impl MjmlEEx.Component
  def render(assigns) do
    """
    <mj-button
      align="center"
      inner-padding="12px 24px"
      padding-left="0px"
      padding-right="0px"
      padding-top="10px"
      padding-bottom="0px"
      href="#{assigns[:cta_url]}"
      background-color="#3d4fa1"
      border-radius="8px"
      color="#fff"
      font-family="Montserrat, Arial, sans-serif"
      font-size="16px"
      font-weight="700"
      font-style="normal"
      line-height="22px"
      letter-spacing="0.5px"
      border="2px solid #3d4fa1"
      css-class="show_on_mobile"
    >
      <span style="text-decoration: none !important;">
        #{assigns[:cta_text]}
      </span>
    </mj-button>
    <mj-button
      align="center"
      inner-padding="18px 40px"
      padding-left="0px"
      padding-right="0px"
      padding-top="10px"
      padding-bottom="18px"
      href="#{assigns[:cta_url]}"
      background-color="#3d4fa1"
      border-radius="8px"
      color="#fff"
      font-family="Montserrat, Arial, sans-serif"
      font-size="18px"
      font-weight="700"
      font-style="normal"
      line-height="24px"
      letter-spacing="0.5px"
      border="2px solid #3d4fa1"
      css-class="show_on_desktop"
    >
      <span style="text-decoration: none !important;">
        #{assigns[:cta_text]}
      </span>
    </mj-button>
    """
  end
end
