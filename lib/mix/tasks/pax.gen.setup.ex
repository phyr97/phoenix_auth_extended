defmodule Mix.Tasks.Pax.Gen.Setup.Docs do
  @moduledoc false

  def short_doc do
    "Generates base authentication setup"
  end

  def example do
    "mix pax.gen.setup Accounts User"
  end

  def long_doc do
    """
    #{short_doc()}

    This task sets up the base authentication structure by:
    * Generating database migrations for authentication
    * Adding required dependencies based on selected auth methods
    * Configuring the application for authentication
    * Setting up WebAuthn hooks (when passkey is enabled)

    ## Example

    ```bash
    #{example()}
    ```

    ## Arguments

    * `context_name` - The context module name (e.g., Accounts)
    * `entity_name` - The name of the entity (e.g., User)

    ## Generated/Modified Files

    * Database migrations in `priv/repo/migrations`
    * Dependencies in `mix.exs`
    * Configuration in `config/config.exs`
    * WebAuthn hooks in `assets/js/app.js` (when passkey enabled)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Setup do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    use PhoenixAuthExtended.Info,
      composes: [
        "pax.gen.setup.config",
        "pax.gen.setup.dependencies",
        "pax.gen.setup.router",
        "pax.gen.setup.layout",
        "pax.gen.setup.hooks"
      ]

    import PhoenixAuthExtended

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> prepare_igniter()
      |> Igniter.compose_task("pax.gen.setup.config", igniter.args.argv)
      |> Igniter.compose_task("pax.gen.setup.dependencies", igniter.args.argv)
      |> Igniter.compose_task("pax.gen.setup.router", igniter.args.argv)
      |> Igniter.compose_task("pax.gen.setup.layout", igniter.args.argv)
      |> compose_task_if("pax.gen.setup.hooks", & &1.assigns.options.passkey, igniter.args.argv)
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Setup do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.setup' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
