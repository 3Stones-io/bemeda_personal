defmodule BemedaPersonal.Accounts.EmailDeliveryTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import Swoosh.TestAssertions

  alias BemedaPersonal.Accounts.EmailDelivery

  describe "deliver/4" do
    test "sends email with proper format" do
      user = user_fixture(%{first_name: "John", last_name: "Doe", email: "john@example.com"})
      subject = "Test Email"
      html_body = "<p>Test HTML</p>"
      text_body = "Test Text"

      {:ok, email} = EmailDelivery.deliver(user, subject, html_body, text_body)

      assert_email_sent(email)
      assert email.to == [{"John Doe", "john@example.com"}]
      assert email.from == {"BemedaPersonal", "contact@mg.bemeda-personal.ch"}
      assert email.subject == subject
      assert email.html_body == html_body
      assert email.text_body == text_body
    end
  end

  describe "put_locale/1" do
    test "sets locale from user preferences" do
      user = user_fixture(%{locale: :de})

      EmailDelivery.put_locale(user)

      assert Gettext.get_locale(BemedaPersonalWeb.Gettext) == "de"
    end
  end
end
