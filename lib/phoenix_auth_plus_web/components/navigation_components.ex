defmodule PhoenixAuthPlusWeb.NavigationComponents do
  @moduledoc """
  Components for navigating the application.
  """
  use Phoenix.Component
  use PhoenixAuthPlusWeb, :verified_routes

  embed_templates "/navigation/*"

  alias PhoenixAuthPlus.Identity.User

  attr :current_user, User, required: true

  def navbar(assigns)

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method)
  slot :inner_block, required: true

  def nav_link(assigns)
end
