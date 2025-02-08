defmodule Mix.Tasks.Pax.Gen.Context.OAuth.Docs do
  @moduledoc false

  def short_doc do
    "Generates OAuth handler for authentication"
  end

  def example do
    "mix pax.gen.context.oauth Accounts User"
  end

  def long_doc do
    """
    #{short_doc()}

    This task generates the OAuth handler for multi-provider authentication:

    * OAuth Handler
      - Manages OAuth provider configurations
      - Handles OAuth callbacks
      - Generates OAuth URLs

    ## Example

    ```bash
    #{example()}
    ```

    ## Generated Files

    The task will create:
    * `lib/your_app/[context]/oauth.ex`

    ## Arguments

    * `context_name` - The context module name (e.g., Accounts)
    * `entity_name` - The name of the entity (e.g., User)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Context.OAuth do
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
      |> generate_oauth()
    end

    defp assign_base_info(igniter) do
      app = Mix.Project.config() |> Keyword.fetch!(:app)
      app_camelized = to_string(app) |> Macro.camelize()
      app_module = Module.concat([app_camelized])
      context_module = Module.concat([app_module, igniter.assigns.context_name])

      igniter
      |> Igniter.assign(:app, app)
      |> Igniter.assign(:app_camelized, app_camelized)
      |> Igniter.assign(:app_module, app_module)
      |> Igniter.assign(:context_module, context_module)
    end

    defp generate_oauth(igniter) do
      assigns = igniter.assigns |> Map.to_list()

      context_path =
        Path.join([
          "lib",
          to_string(igniter.assigns.app),
          String.downcase(igniter.assigns.context_name)
        ])

      file_path = Path.join(context_path, "oauth.ex")

      igniter
      |> Igniter.copy_template(
        "priv/templates/schemas/oauth.eex",
        file_path,
        assigns
      )
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Context.OAuth do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.context.oauth' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
