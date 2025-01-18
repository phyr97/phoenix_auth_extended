defmodule PhoenixAuthExtendedWeb.UserLoginLive do
  use PhoenixAuthExtendedWeb, :live_view

  alias WebauthnComponents.{AuthenticationComponent, SupportComponent}

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {
      :ok,
      socket
      |> assign(:page_title, "Sign In")
      |> assign(:token_form, nil)
      |> assign(form: form),
      temporary_assigns: [form: form]
    }
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Log in to account
        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <div class="flex flex-col gap-2 w-full">
            <.button phx-disable-with="Logging in..." class="w-full">
              Log in <span aria-hidden="true">→</span>
            </.button>
          </div>
        </:actions>
      </.simple_form>

      <div class="mx-auto w-96">
        <.live_component module={SupportComponent} id="support-component" />
        <.live_component
          disabled={false}
          module={AuthenticationComponent}
          id="authentication-component"
          display_text="Log in with passkey"
          class={[
            "mt-4 rounded-lg border border-zinc-900 hover:bg-zinc-100 py-2 px-3",
            "text-sm font-semibold leading-6 text-zinc-900 active:text-zinc-700",
            "flex gap-2 items-center justify-center w-full",
            "disabled:cursor-not-allowed disabled:opacity-25"
          ]}
        />
        <PhoenixAuthExtendedWeb.PasskeyComponents.guidance />
        <PhoenixAuthExtendedWeb.PasskeyComponents.token_form form={@token_form} />
      </div>
    </div>
    """
  end
end
