defmodule PhoenixAuthExtendedTestWeb.LoginLive do
  alias PhoenixAuthExtendedTest.Accounts.User
  use PhoenixAuthExtendedTestWeb, :live_view

  require Logger

  alias PhoenixAuthExtendedTest.Accounts
  alias PhoenixAuthExtendedTest.Accounts.UserToken

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

        <.link
          navigate={~p"/oauth/github"}
          class={[
            "mt-4 rounded-lg border border-zinc-900 hover:bg-zinc-100 py-2 px-3",
            "text-sm font-semibold leading-6 text-zinc-900 active:text-zinc-700",
            "flex gap-2 items-center justify-center w-full",
            "disabled:cursor-not-allowed disabled:opacity-25"
          ]}
        >
          Log in with GitHub
        </.link>

        <.button_link navigate={~p"/users/register_with_passkey"} class="w-full">
          <.icon name="hero-key" class="h-4 w-4" /> Register with passkey
        </.button_link>
        <PhoenixAuthExtendedTestWeb.Components.PasskeyComponents.guidance />
        <PhoenixAuthExtendedTestWeb.Components.PasskeyComponents.token_form form={@token_form} />
      </div>
    </div>
    """
  end

  def handle_event(event, params, socket) do
    Logger.warning(unhandled_event: {__MODULE__, event, params})
    {:noreply, socket}
  end

  def handle_info({:passkeys_supported, supported?}, socket) do
    if supported? do
      {:noreply, socket}
    else
      {
        :noreply,
        socket
        |> put_flash(:error, "Passkeys are not supported in this browser.")
      }
    end
  end

  def handle_info({:find_credential, [key_id: key_id]}, socket) do
    case Accounts.get_by_key_id(key_id) do
      %User{keys: keys} = user ->
        send_update(AuthenticationComponent, id: "authentication-component", user_keys: keys)

        {
          :noreply,
          socket
          |> assign(:user, user)
        }

      nil ->
        {
          :noreply,
          socket
          |> put_flash(:error, "Failed to sign in")
          |> assign(:token_form, nil)
        }
    end
  end

  def handle_info({:authentication_successful, _auth_data}, socket) do
    case Accounts.generate_user_session_token(socket.assigns.user) do
      {:ok, %UserToken{value: token_value}} ->
        encoded_token = Base.encode64(token_value, padding: false)
        token_attrs = %{"value" => encoded_token}

        {:noreply, assign(socket, :token_form, to_form(token_attrs, as: "token"))}

      {:error, changeset} ->
        Logger.warning(authentication_error: {__MODULE__, changeset})

        {
          :noreply,
          socket
          |> put_flash(:error, "Failed to sign in")
          |> assign(:token_form, nil)
        }
    end
  end

  def handle_info({:authentication_failure, message: message}, socket) do
    Logger.error(authentication_error: {__MODULE__, message})

    {
      :noreply,
      socket
      |> put_flash(:error, "Failed to sign in")
      |> assign(:token_form, nil)
    }
  end

  def handle_info(
        {:error,
         %{"message" => message, "name" => "NoUserVerifyingPlatformAuthenticatorAvailable"}},
        socket
      ) do
    socket
    |> assign(:token_form, nil)
    |> put_flash(:error, message)
    |> then(&{:noreply, &1})
  end

  def handle_info(message, socket) do
    Logger.warning(unhandled_message: {__MODULE__, message})
    {:noreply, socket}
  end
end
