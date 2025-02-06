defmodule Mix.Tasks.Pax.Gen.Schema.Docs do
  @moduledoc false

  def short_doc do
    "Generates schema and migrations for authentication"
  end

  def example do
    "mix pax.gen.schema Accounts User"
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
  defmodule Mix.Tasks.Pax.Gen.Schema do
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
        composes: ["pax.gen.schema.migrations"],
        schema: [],
        defaults: [],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> Igniter.compose_task("pax.gen.schema.migrations", igniter.args.argv)
      |> Igniter.compose_task("pax.gen.schema.schemas", igniter.args.argv)
      |> Igniter.compose_task("pax.gen.schema.notifier", igniter.args.argv)
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Schema do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.schema' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
