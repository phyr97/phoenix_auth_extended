defmodule Mix.Tasks.Pax.Gen.Live.Docs do
  @moduledoc false

  def short_doc do
    "Generates LiveView components for authentication"
  end

  def example do
    "mix pax.gen.live Accounts User"
  end

  def long_doc do
    """
    #{short_doc()}

    This task generates LiveView components for authentication:

    * Core Phoenix components
      - Adjusts form spacing
      - Adds button link component

    * Passkey components (when passkey enabled)
      - Guidance component for passkey explanation
      - Token form for authentication
      - Main passkey components module

    ## Example

    ```bash
    #{example()}
    ```

    ## Arguments

    * `context_name` - The context module name (e.g., Accounts)
    * `entity_name` - The name of the entity (e.g., User)

    ## Options

    This task inherits options from the auth generator:
    * `--passkey` - Generates additional passkey components
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Live do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    import PhoenixAuthExtended
    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_auth_extended,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        positional: [:context_name, :entity_name],
        composes: [
          "pax.gen.live.components.phoenix",
          "pax.gen.live.components.passkey",
          "pax.gen.live.controllers"
        ],
        schema: [],
        defaults: [],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> prepare_igniter()
      |> Igniter.assign(igniter.args.positional)
      |> assign_base_info()
      |> generate_live_views()
      |> Igniter.compose_task("pax.gen.live.components.phoenix", igniter.args.argv)
      |> maybe_generate_passkey_components()
      |> Igniter.compose_task("pax.gen.live.controllers", igniter.args.argv)
    end

    defp assign_base_info(igniter) do
      app = Mix.Project.config() |> Keyword.fetch!(:app)
      app_module_name = to_string(app) |> Macro.camelize()
      app_module = Module.concat([app_module_name])
      app_web_module = Module.concat([app_module, "Web"])
      context_module = Module.concat([app_module, igniter.assigns.context_name])

      igniter
      |> Igniter.assign(:app, app)
      |> Igniter.assign(:app_module_name, app_module_name)
      |> Igniter.assign(:app_module, app_module)
      |> Igniter.assign(:app_web_module, app_web_module)
      |> Igniter.assign(:context_module, context_module)
    end

    defp generate_live_views(igniter) do
      live_views = [
        {"user_registration_live.eex", "user_registration_live.ex"},
        {"user_login_live.eex", "user_login_live.ex"},
        {"user_confirmation_live.eex", "user_confirmation_live.ex"},
        {"user_confirmation_instructions_live.eex", "user_confirmation_instructions_live.ex"},
        {"user_forgot_password_live.eex", "user_forgot_password_live.ex"},
        {"user_reset_password_live.eex", "user_reset_password_live.ex"},
        {"user_settings_live.eex", "user_settings_live.ex"},
        {"passkey_registration_live.eex", "passkey_registration_live.ex"}
      ]

      Enum.reduce(live_views, igniter, fn {template, file}, acc ->
        generate_live_view(acc, template, file)
      end)
    end

    defp generate_live_view(igniter, template_name, file_name) do
      assigns = Map.to_list(igniter.assigns)
      web_path = Path.join(["lib", to_string(igniter.assigns.app) <> "_web", "live"])
      file_path = Path.join(web_path, file_name)

      igniter
      |> Igniter.copy_template(
        "priv/templates/live/#{template_name}",
        file_path,
        assigns
      )
    end

    defp maybe_generate_passkey_components(%{assigns: %{options: %{passkey: true}}} = igniter) do
      Igniter.compose_task(igniter, "pax.gen.live.components.passkey", igniter.args.argv)
    end

    defp maybe_generate_passkey_components(igniter), do: igniter
  end
else
  defmodule Mix.Tasks.Pax.Gen.Live do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.live' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
