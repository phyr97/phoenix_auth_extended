defmodule PhoenixAuthExtendedWeb.PasskeyComponents do
  @moduledoc """
  Components for navigating the application.
  """
  use Phoenix.Component
  use PhoenixAuthExtendedWeb, :verified_routes
  import PhoenixAuthExtendedWeb.CoreComponents
  alias Phoenix.LiveView.JS

  embed_templates "/passkeys/*"

  def guidance(assigns)

  attr :form, Phoenix.HTML.Form,
    required: true,
    doc: "Form used to create a session upon successful registration or authentication."

  def token_form(assigns)
end
