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

    use PhoenixAuthExtended.Info,
      composes: [
        "pax.gen.context.migrations",
        "pax.gen.context.schemas",
        "pax.gen.context.notifier",
        "pax.gen.context.o_auth"
      ]

    import PhoenixAuthExtended

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      argv = igniter.args.argv

      igniter
      |> prepare_igniter()
      |> generate_context()
      |> Igniter.compose_task("pax.gen.context.migrations", argv)
      |> Igniter.compose_task("pax.gen.context.schemas", argv)
      |> compose_task_if("pax.gen.context.o_auth", & &1.assigns.options.oauth, argv)
      |> compose_task_if("pax.gen.context.notifier", &is_email_basic_identifier/1, argv)
    end

    defp is_email_basic_identifier(%{assigns: %{options: %{basic_identifier: "email"}}}), do: true
    defp is_email_basic_identifier(_), do: false

    defp generate_context(igniter) do
      template = Path.join([template_path(), "context.eex"])

      file_path =
        Path.join([
          app_path(),
          String.downcase(igniter.assigns.context_name),
          "#{String.downcase(igniter.assigns.context_name)}.ex"
        ])

      copy_template(igniter, template, file_path)
    end
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
