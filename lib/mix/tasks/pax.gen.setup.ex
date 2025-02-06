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

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :phoenix_auth_extended,
        # dependencies to add
        adds_deps: [],
        # dependencies to add and call their associated installers, if they exist
        installs: [],
        # An example invocation
        example: __MODULE__.Docs.example(),
        # a list of positional arguments, i.e `[:file]`
        positional: [:context_name, :entity_name],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [
          "pax.gen.setup.config",
          "pax.gen.setup.dependencies",
          "pax.gen.setup.router",
          "pax.gen.setup.layout",
          "pax.gen.setup.components",
          "pax.gen.setup.hooks"
        ],
        # `OptionParser` schema
        schema: [],
        # Default values for the options in the `schema`
        defaults: [],
        # CLI aliases
        aliases: [],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> Igniter.compose_task("pax.gen.setup.config", [])
      |> Igniter.compose_task("pax.gen.setup.dependencies", [])
      |> Igniter.compose_task("pax.gen.setup.router", [])
      |> Igniter.compose_task("pax.gen.setup.layout", [])
      |> Igniter.compose_task("pax.gen.setup.components", [])
      |> maybe_add_hooks()
    end

    defp maybe_add_hooks(%{assigns: %{auth_options: %{passkey: true}}} = igniter),
      do: Igniter.compose_task(igniter, "pax.gen.setup.hooks", [])

    defp maybe_add_hooks(igniter), do: igniter
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
