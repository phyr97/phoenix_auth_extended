defmodule Mix.Tasks.Pax.Gen.Setup.Router.Docs do
  @moduledoc false

  def short_doc do
    "Configures the router for authentication"
  end

  def example do
    "mix pax.gen.setup.router"
  end

  def long_doc do
    """
    #{short_doc()}

    This task updates the router configuration by adding the required authentication routes:

    ## Added Routes
    * Basic auth routes (always included)
      - Registration
      - Login/Logout
      - Password reset
      - Email confirmation
      - User settings

    * OAuth routes (when OAuth enabled)
      - OAuth provider request/callback

    * Passkey routes (when passkey enabled)
      - WebAuthn registration

    ## Example

        #{example()}

    ## Modified Files

    The task will modify:
    * `lib/your_app_web/router.ex`
      - Adds UserAuth import
      - Adds authentication routes
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Setup.Router do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_auth_extended,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        positional: [],
        composes: [],
        schema: [],
        defaults: [],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      {igniter, router_module} = Igniter.Libs.Phoenix.select_router(igniter)

      igniter
      |> add_user_auth_import(router_module)
      |> add_fetch_current_user_plug()
      |> add_routes(router_module)
    end

    # Imports
    defp add_user_auth_import(igniter, router_module) do
      web_module = Igniter.Libs.Phoenix.web_module(igniter)
      user_auth_module = Module.concat([web_module, "UserAuth"])
      code = "import #{inspect(user_auth_module)}"

      {:ok, igniter} = add_import_to_router(igniter, router_module, code)
      igniter
    end

    defp add_import_to_router(igniter, module, code) do
      Igniter.Project.Module.find_and_update_module(igniter, module, fn zipper ->
        {:ok, zipper} = Igniter.Libs.Phoenix.move_to_router_use(igniter, zipper)

        {:ok, Igniter.Code.Common.add_code(zipper, code, placement: :after)}
      end)
    end

    # Pipeline
    defp add_fetch_current_user_plug(igniter) do
      Igniter.Libs.Phoenix.append_to_pipeline(igniter, :browser, "plug :fetch_current_user")
    end

    # Routes
    defp add_routes(%{assigns: %{auth_options: auth_options}} = igniter, router_module) do
      web_module = Igniter.Libs.Phoenix.web_module(igniter)
      routes = authentication_routes(web_module, auth_options)

      {:ok, igniter} = add_code_to_router(igniter, router_module, routes)
      igniter
    end

    defp add_code_to_router(igniter, router, code) do
      Igniter.Project.Module.find_and_update_module(igniter, router, fn zipper ->
        {:ok, Igniter.Code.Common.add_code(zipper, code)}
      end)
    end

    defp authentication_routes(web_module, %{oauth: oauth?, passkey: passkey?}) do
      """
      scope "/", #{inspect(web_module)} do
        pipe_through [:browser, :redirect_if_user_is_authenticated]

        live_session :redirect_if_user_is_authenticated,
          on_mount: [{#{inspect(web_module)}.UserAuth, :redirect_if_user_is_authenticated}] do
          live "/users/register", UserRegistrationLive, :new
          #{if passkey?, do: "live \"/users/register_with_passkey\", PasskeyRegistrationLive, :new"}
          live "/users/log_in", UserLoginLive, :new
          live "/users/reset_password", UserForgotPasswordLive, :new
          live "/users/reset_password/:token", UserResetPasswordLive, :edit
        end

        #{if oauth? do
        """
        get "/oauth/:provider", OAuthController, :request
        get "/oauth/:provider/callback", OAuthController, :callback
        """
      end}
        post "/users/log_in", UserSessionController, :create
      end

      scope "/", #{inspect(web_module)} do
        pipe_through [:browser, :require_authenticated_user]

        live_session :require_authenticated_user,
          on_mount: [{#{inspect(web_module)}.UserAuth, :ensure_authenticated}] do
          live "/users/settings", UserSettingsLive, :edit
          live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
        end
      end

      scope "/", #{inspect(web_module)} do
        pipe_through [:browser]

        delete "/users/log_out", UserSessionController, :delete

        live_session :current_user,
          on_mount: [{#{inspect(web_module)}.UserAuth, :mount_current_user}] do
          live "/users/confirm/:token", UserConfirmationLive, :edit
          live "/users/confirm", UserConfirmationInstructionsLive, :new
        end
      end
      """
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Setup.Router do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.setup.router' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
