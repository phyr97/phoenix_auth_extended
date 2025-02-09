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
      - Settings

    * OAuth routes (when OAuth enabled)
      - OAuth provider request/callback

    * Passkey routes (when passkey enabled)
      - WebAuthn registration

    ## Example

        #{example()}

    ## Modified Files

    The task will modify:
    * `lib/your_app_web/router.ex`
      - Adds Auth import
      - Adds authentication routes
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Setup.Router do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    import PhoenixAuthExtended

    alias PhoenixAuthExtended.Info

    @impl Igniter.Mix.Task
    def info(argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_auth_extended,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        positional: [],
        composes: [],
        schema: Info.options(),
        defaults: Info.defaults(),
        aliases: Info.aliases(),
        required: Info.required_options(argv)
      }
    end

    @impl Igniter.Mix.Task
    @spec igniter(Igniter.t()) :: Igniter.t()
    def igniter(igniter) do
      {igniter, router_module} = Igniter.Libs.Phoenix.select_router(igniter)

      igniter
      |> prepare_igniter()
      |> add_auth_import(router_module)
      |> add_fetch_current_plug()
      |> add_routes(router_module)
    end

    # Imports
    defp add_auth_import(igniter, router_module) do
      web_module = Igniter.Libs.Phoenix.web_module(igniter)
      auth_module = Module.concat([web_module, "Auth"])
      code = "import #{inspect(auth_module)}"

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
    defp add_fetch_current_plug(igniter) do
      Igniter.Libs.Phoenix.append_to_pipeline(
        igniter,
        :browser,
        "plug :fetch_current_#{String.downcase(igniter.assigns.entity_name)}"
      )
    end

    # Routes
    defp add_routes(igniter, router_module) do
      web_module = Igniter.Libs.Phoenix.web_module(igniter)
      routes = authentication_routes(igniter, web_module)

      {:ok, igniter} = add_code_to_router(igniter, router_module, routes)
      igniter
    end

    defp add_code_to_router(igniter, router, code) do
      Igniter.Project.Module.find_and_update_module(igniter, router, fn zipper ->
        {:ok, Igniter.Code.Common.add_code(zipper, code)}
      end)
    end

    defp authentication_routes(%{assigns: %{options: options}} = igniter, web_module) do
      entity = String.downcase(igniter.assigns.entity_name)

      """
      scope "/", #{inspect(web_module)} do
        pipe_through [:browser, :redirect_if_#{entity}_is_authenticated]

        live_session :redirect_if_#{entity}_is_authenticated,
          on_mount: [{#{inspect(web_module)}.Auth, :redirect_if_#{entity}_is_authenticated}] do
          live "/#{entity}s/register", RegistrationLive, :new
          #{if options.passkey, do: "live \"/#{entity}s/register_with_passkey\", PasskeyRegistrationLive, :new"}
          live "/#{entity}s/log_in", LoginLive, :new
          live "/#{entity}s/reset_password", ForgotPasswordLive, :new
          live "/#{entity}s/reset_password/:token", ResetPasswordLive, :edit
        end

        #{if options.oauth do
        """
        get "/oauth/:provider", OAuthController, :request
        get "/oauth/:provider/callback", OAuthController, :callback
        """
      end}
        post "/#{entity}s/log_in", SessionController, :create
      end

      scope "/", #{inspect(web_module)} do
        pipe_through [:browser, :require_authenticated_#{entity}]

        live_session :require_authenticated_#{entity},
          on_mount: [{#{inspect(web_module)}.Auth, :ensure_authenticated}] do
          live "/#{entity}s/settings", SettingsLive, :edit
          live "/#{entity}s/settings/confirm_email/:token", SettingsLive, :confirm_email
        end
      end

      scope "/", #{inspect(web_module)} do
        pipe_through [:browser]

        delete "/#{entity}s/log_out", SessionController, :delete

        live_session :current_#{entity},
          on_mount: [{#{inspect(web_module)}.Auth, :mount_current_#{entity}}] do
          live "/#{entity}s/confirm/:token", ConfirmationLive, :edit
          live "/#{entity}s/confirm", ConfirmationInstructionsLive, :new
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
