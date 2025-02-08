defmodule Mix.Tasks.Pax.Gen.Context.Docs do
  @moduledoc false

  def short_doc do
    "Generates schema and migrations for authentication"
  end

  def example do
    "mix pax.gen.context Accounts User"
  end

  def long_doc do
    """
    #{short_doc()}

    This task generates the schema and migrations for authentication:

    * Creates migration files for:
      - Base entity table (e.g. users)
      - Token table (e.g. user_tokens)
      - Keys table (when passkey option enabled)

    * Generates Ecto schema files for:
      - Main entity (e.g. User)
      - Token schema
      - Key schema (when passkey option enabled)

    ## Example

    ```bash
    #{example()}
    ```

    ## Arguments

    * `context_name` - The context module name (e.g., Accounts)
    * `entity_name` - The name of the entity (e.g., User)

    ## Options

    This task inherits options from the auth generator:
    * `--passkey` - Generates additional schemas and migrations for WebAuthn/FIDO2
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Context do
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
        composes: ["pax.gen.context.migrations"],
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
      |> Igniter.compose_task("pax.gen.context.migrations", igniter.args.argv)
      |> Igniter.compose_task("pax.gen.context.schemas", igniter.args.argv)
      |> generate_context()
      |> maybe_generate_notifier()
      |> maybe_generate_oauth()
    end

    defp assign_base_info(igniter) do
      app = Mix.Project.config() |> Keyword.fetch!(:app)
      app_module_name = to_string(app) |> Macro.camelize()
      app_module = Module.concat([app_module_name])
      context_module = Module.concat([app_module, igniter.assigns.context_name])

      igniter
      |> Igniter.assign(:app, app)
      |> Igniter.assign(:app_module_name, app_module_name)
      |> Igniter.assign(:app_module, app_module)
      |> Igniter.assign(:context_module, context_module)
      |> Igniter.assign(:timestamp_type, :utc_datetime)
    end

    defp generate_context(igniter) do
      assigns = igniter.assigns |> Map.to_list()

      context_path =
        Path.join([
          "lib",
          to_string(igniter.assigns.app),
          String.downcase(igniter.assigns.context_name)
        ])

      file_path = Path.join(context_path, "#{String.downcase(igniter.assigns.context_name)}.ex")

      igniter
      |> Igniter.copy_template(
        "priv/templates/context.eex",
        file_path,
        assigns
      )
    end

    defp maybe_generate_notifier(
           %{assigns: %{auth_options: %{basic_identifier: "email"}}} = igniter
         ) do
      Igniter.compose_task(igniter, "pax.gen.context.notifier", igniter.args.argv)
    end

    defp maybe_generate_notifier(igniter), do: igniter

    defp maybe_generate_oauth(%{assigns: %{auth_options: %{oauth: true}}} = igniter) do
      Igniter.compose_task(igniter, "pax.gen.context.o_auth", igniter.args.argv)
    end

    defp maybe_generate_oauth(igniter), do: igniter
  end
else
  defmodule Mix.Tasks.Pax.Gen.Context do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.context' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
