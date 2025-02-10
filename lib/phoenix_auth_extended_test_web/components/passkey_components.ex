defmodule PhoenixAuthExtendedTestWeb.Components.PasskeyComponents do
  @moduledoc """
  Components for navigating the application.
  """
  use Phoenix.Component
  use PhoenixAuthExtendedTestWeb, :verified_routes
  import PhoenixAuthExtendedTestWeb.CoreComponents
  alias Phoenix.LiveView.JS

  def guidance(assigns) do
    ~H"""
    <details class="grid group">
      <summary class={[
        "py-2 mt-6 cursor-pointer transition select-none",
        "font-semibold",
        "rounded-lg",
        "group-open:border-gray-300"
      ]}>
        Where's the password?
      </summary>

      <div class=" px-2text-justify grid gap-2">
        <p>
          This application uses a new technology that replaces passwords and temporary codes.
        </p>

        <p>
          <a href="https://fidoalliance.org/passkeys/" class="font-bold" target="_blank">
            Passkeys
          </a>
          are a more secure way to sign into applications. They use advanced technology embraced by security experts, while improving ease-of-use.
        </p>

        <p>
          Read more about Passkeys at the <a
            href="https://fidoalliance.org/passkeys/#faq"
            class="font-bold"
            target="_blank"
          >
                FIDO Alliance
              </a>.
        </p>
      </div>
    </details>
    """
  end

  # - The form is only rendered when a token has been created by the registration or authentication component.
  # - The form is present in the markup, but hidden from view.
  # - When the form is mounted, JS is used to click the submit button.
  # - This is a bit hacky, but it works.

  attr :form, Phoenix.HTML.Form,
    required: false,
    doc: "Form used to create a session upon successful registration or authentication."

  def token_form(assigns) do
    ~H"""
    <.simple_form
      :if={@form}
      for={@form}
      method="post"
      id="token-form"
      action={~p"/users/log_in?_action=registered"}
      phx-mounted={JS.dispatch("click", to: "#token-form button[type='submit']")}
      class="hidden"
    >
      <.input type="text" field={@form[:value]} label="Value" />
      <.button type="submit">Go</.button>
    </.simple_form>
    """
  end
end
