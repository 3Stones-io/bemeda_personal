defmodule BemedaPersonalWeb.Storybook.Core.Input do
  use PhoenixStorybook.Story, :component

  alias BemedaPersonalWeb.Components.Core.Form
  alias PhoenixStorybook.Stories.Variation

  @type description :: String.t()

  @spec function() :: function()
  def function, do: &Form.input/1

  @spec description() :: description()
  def description, do: "Input component matching Figma design system"

  @spec variations() :: [PhoenixStorybook.Stories.Variation.t()]
  def variations do
    [
      %Variation{
        id: :default,
        description: "Default input",
        attributes: %{
          id: "email",
          name: "email",
          type: "email",
          label: "Email Address",
          placeholder: "Enter your email",
          value: ""
        }
      },
      %Variation{
        id: :with_value,
        description: "Input with value",
        attributes: %{
          id: "name",
          name: "name",
          type: "text",
          label: "Full Name",
          value: "John Doe"
        }
      },
      %Variation{
        id: :with_error,
        description: "Input with validation error",
        attributes: %{
          id: "password",
          name: "password",
          type: "password",
          label: "Password",
          value: "",
          errors: ["Password must be at least 8 characters"]
        }
      },
      %Variation{
        id: :required,
        description: "Required input",
        attributes: %{
          id: "username",
          name: "username",
          type: "text",
          label: "Username",
          value: "",
          required: true,
          placeholder: "Choose a username"
        }
      },
      %Variation{
        id: :disabled,
        description: "Disabled input",
        attributes: %{
          id: "disabled_field",
          name: "disabled_field",
          type: "text",
          label: "Disabled Field",
          value: "Cannot edit this",
          disabled: true
        }
      },
      %Variation{
        id: :textarea,
        description: "Textarea input",
        attributes: %{
          id: "description",
          name: "description",
          type: "textarea",
          label: "Description",
          value: "",
          rows: 4,
          placeholder: "Enter a description"
        }
      },
      %Variation{
        id: :select,
        description: "Select dropdown",
        attributes: %{
          id: "country",
          name: "country",
          type: "select",
          label: "Country",
          prompt: "Choose a country",
          options: [
            {"Switzerland", "CH"},
            {"Germany", "DE"},
            {"France", "FR"},
            {"Italy", "IT"}
          ]
        }
      },
      %Variation{
        id: :checkbox,
        description: "Checkbox input",
        attributes: %{
          id: "terms",
          name: "terms",
          type: "checkbox",
          label: "I agree to the terms and conditions",
          checked: false
        }
      },
      %Variation{
        id: :number,
        description: "Number input",
        attributes: %{
          id: "age",
          name: "age",
          type: "number",
          label: "Age",
          min: 18,
          max: 100,
          value: 25
        }
      },
      %Variation{
        id: :date,
        description: "Date input",
        attributes: %{
          id: "birthdate",
          name: "birthdate",
          type: "date",
          label: "Birth Date",
          value: ""
        }
      },
      %Variation{
        id: :all_text_types,
        description: "Various text input types",
        template: """
        <div class="space-y-6">
          <.input id="email_example" name="email_example" type="email" label="Email" value="" placeholder="john@example.com" />
          <.input id="tel_example" name="tel_example" type="tel" label="Phone" value="" placeholder="+41 79 123 45 67" />
          <.input id="url_example" name="url_example" type="url" label="Website" value="" placeholder="https://example.com" />
          <.input id="search_example" name="search_example" type="search" label="Search" value="" placeholder="Search..." />
        </div>
        """
      }
    ]
  end
end
