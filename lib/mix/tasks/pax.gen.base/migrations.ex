defmodule Mix.Tasks.Pax.Gen.Base.Migrations.Docs do
  @moduledoc false

  def short_doc do
    "A short description of your task"
  end

  def example do
    "mix pax.gen.base.migrations --example arg"
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
  defmodule Mix.Tasks.Pax.Gen.Base.Migrations do
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
        composes: [],
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
      igniter = assign_base_info(igniter)
      migration_file_name = build_migration_file_name(igniter)
      entity_assigns = build_entity_migration_assigns(igniter)

      igniter
      |> Igniter.copy_template(
        "priv/templates/migrations/entity.eex",
        "priv/repo/migrations/#{migration_file_name}",
        entity_assigns
      )
    end

    defp assign_base_info(igniter) do
      app = Mix.Project.config() |> Keyword.fetch!(:app)
      app_camelized = to_string(app) |> Macro.camelize()
      app_repo = Module.concat([app_camelized, "Repo"])

      igniter
      |> Igniter.assign(:app, app)
      |> Igniter.assign(:app_camelized, app_camelized)
      |> Igniter.assign(:app_repo, app_repo)
    end

    defp build_migration_file_name(igniter) do
      entity_name = igniter.args.positional[:entity_name]
      migration_name = "create_#{entity_name}_table"
      timestamp = NaiveDateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")
      "#{timestamp}_#{migration_name}.exs"
    end

    defp build_entity_migration_assigns(igniter) do
      entity_name = igniter.args.positional[:entity_name]

      [
        repo: igniter.assigns.app_repo,
        timestamp_type: :utc_datetime,
        migration_name: "create_#{entity_name}_table" |> Macro.camelize(),
        entity_name: entity_name
      ]
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Base.Migrations do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.base.migrations' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
