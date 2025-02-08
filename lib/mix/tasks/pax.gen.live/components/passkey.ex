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
      |> Igniter.assign(igniter.args.positional)
      |> assign_base_info()
      |> generate_passkey_components()
    end

    defp assign_base_info(igniter) do
      app = Mix.Project.config() |> Keyword.fetch!(:app)
      app_camelized = to_string(app) |> Macro.camelize()
      app_module = Module.concat([app_camelized])
      web_module = Igniter.Libs.Phoenix.web_module(igniter)

      igniter
      |> Igniter.assign(:app, app)
      |> Igniter.assign(:app_camelized, app_camelized)
      |> Igniter.assign(:app_module, app_module)
      |> Igniter.assign(:web_module, web_module)
    end

    defp generate_passkey_components(igniter) do
      web_path = Path.join(["lib", Macro.underscore(igniter.assigns.web_module)])

      igniter
      |> generate_component(
        "components/passkey_components.eex",
        "components/passkey_components.ex",
        web_path
      )
      |> create_passkeys_directory(web_path)
      |> copy_heex_templates(web_path)
    end

    defp generate_component(igniter, template, target_path, web_path) do
      file_path = Path.join(web_path, target_path)

      igniter
      |> Igniter.copy_template(
        "priv/templates/components/#{template}",
        file_path,
        igniter.assigns |> Map.to_list()
      )
    end

    defp create_passkeys_directory(igniter, web_path) do
      passkeys_path = Path.join([web_path, "components", "passkeys"])
      Igniter.mkdir(igniter, passkeys_path)
    end

    defp copy_heex_templates(igniter, web_path) do
      guidance_path = Path.join(web_path, "components/passkeys/guidance.html.heex")
      token_form_path = Path.join(web_path, "components/passkeys/token_form.html.heex")

      igniter
      |> Igniter.create_new_file(
        guidance_path,
        File.read!("priv/templates/components/passkeys/guidance.html.heex")
      )
      |> Igniter.create_new_file(
        token_form_path,
        File.read!("priv/templates/components/passkeys/token_form.html.heex")
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
