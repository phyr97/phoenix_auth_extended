defmodule Mix.Tasks.Pax.Gen.Base.Docs do
  @moduledoc false

  def short_doc do
    "A short description of your task"
  end

  def example do
    "mix pax.gen.base --example arg"
  end

  def long_doc do
    """
    #{short_doc()}

    Longer explanation of your task

    ## Example

    ```bash
    #{example()}
    ```

    ## Options

    * `--example-option` or `-e` - Docs for your option
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Base do
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
        positional: [:entity_name],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: ["pax.gen.base.migrations"],
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
      |> Igniter.compose_task("pax.gen.base.migrations", [igniter.args.positional[:entity_name]])
      |> Igniter.compose_task("pax.gen.base.config", [])
      |> maybe_add_hooks()
    end

    defp maybe_add_hooks(%{assigns: %{auth_options: %{passkey: true}}} = igniter),
      do: Igniter.compose_task(igniter, "pax.gen.base.hooks", [])

    defp maybe_add_hooks(igniter), do: igniter
  end
else
  defmodule Mix.Tasks.Pax.Gen.Base do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.base' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
