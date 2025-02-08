defmodule Mix.Tasks.Pax.Gen.Context.Notifier.Docs do
  @moduledoc false

  def short_doc do
    "Generates notifier module for authentication emails"
  end

  def example do
    "mix pax.gen.context.notifier Accounts User"
  end

  def long_doc do
    """
    #{short_doc()}

    This task generates the notifier module for sending authentication-related emails:

    * Email confirmation instructions
    * Password reset instructions
    * Email change instructions

    ## Example

    ```bash
    #{example()}
    ```

    ## Generated Files

    The task will create:
    * `lib/your_app/[context]/[entity]_notifier.ex`

    ## Arguments

    * `context_name` - The context module name (e.g., Accounts)
    * `entity_name` - The name of the entity (e.g., User)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Context.Notifier do
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
      |> generate_notifier()
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
    end

    defp generate_notifier(igniter) do
      assigns = igniter.assigns |> Map.to_list()

      context_path =
        Path.join([
          "lib",
          to_string(igniter.assigns.app),
          String.downcase(igniter.assigns.context_name)
        ])

      file_path =
        Path.join(context_path, "#{String.downcase(igniter.assigns.entity_name)}_notifier.ex")

      igniter
      |> Igniter.copy_template(
        "priv/templates/schemas/entity_notifier.eex",
        file_path,
        assigns
      )
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Context.Notifier do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.context.notifier' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
