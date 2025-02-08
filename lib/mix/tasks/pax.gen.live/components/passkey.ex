defmodule Mix.Tasks.Pax.Gen.Live.Components.Passkey.Docs do
  @moduledoc false

  def short_doc do
    "Generates passkey components for authentication"
  end

  def example do
    "mix pax.gen.live.components.passkey Accounts User"
  end

  def long_doc do
    """
    #{short_doc()}

    This task generates the passkey components for authentication:

    * Main passkey components module
    * Guidance component for passkey explanation
    * Token form for authentication

    ## Example

    ```bash
    #{example()}
    ```

    ## Arguments

    * `context_name` - The context module name (e.g., Accounts)
    * `entity_name` - The name of the entity (e.g., User)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Live.Components.Passkey do
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
        composes: [],
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
      |> generate_passkey_components()
    end

    defp assign_base_info(igniter) do
      app = Mix.Project.config() |> Keyword.fetch!(:app)
      app_module_name = to_string(app) |> Macro.camelize()
      app_module = Module.concat([app_module_name])
      web_module = Igniter.Libs.Phoenix.web_module(igniter)

      igniter
      |> Igniter.assign(:app, app)
      |> Igniter.assign(:app_module_name, app_module_name)
      |> Igniter.assign(:app_module, app_module)
      |> Igniter.assign(:web_module, web_module)
    end

    defp generate_passkey_components(igniter) do
      web_path = Path.join(["lib", Macro.underscore(igniter.assigns.web_module)])
      components_path = Path.join(web_path, "components")

      igniter
      |> Igniter.copy_template(
        "priv/templates/components/passkey_components.eex",
        Path.join(components_path, "passkey_components.ex"),
        igniter.assigns |> Map.to_list(),
        on_exists: :warning
      )
      |> create_passkeys_directory(components_path)
      |> copy_heex_templates(components_path)
    end

    defp create_passkeys_directory(igniter, components_path) do
      passkeys_path = Path.join(components_path, "passkey_components")
      Igniter.mkdir(igniter, passkeys_path)
    end

    defp copy_heex_templates(igniter, components_path) do
      passkeys_path = Path.join(components_path, "passkey_components")

      igniter
      |> Igniter.create_new_file(
        Path.join(passkeys_path, "guidance.html.heex"),
        File.read!("priv/templates/components/guidance.html.heex"),
        on_exists: :warning
      )
      |> Igniter.create_new_file(
        Path.join(passkeys_path, "token_form.html.heex"),
        File.read!("priv/templates/components/token_form.html.heex"),
        on_exists: :warning
      )
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Live.Components.Passkey do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.live.components.passkey' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
