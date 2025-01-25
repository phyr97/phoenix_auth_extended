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
      entity_name = igniter.args.positional[:entity_name]

      igniter
      |> Igniter.assign(:entity_name, entity_name)
      |> assign_base_info()
      |> generate_migration("entities.eex", "create_#{entity_name}_table")
      |> generate_migration("entity_tokens.eex", "create_#{entity_name}_tokens_table")
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

    defp generate_migration(igniter, template_name, migration_name) do
      timestamp = NaiveDateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")
      file_name_with_timestamp = "#{timestamp}_#{migration_name}.exs"
      assigns = build_assigns(igniter, migration_name)

      Igniter.copy_template(
        igniter,
        "priv/templates/migrations/#{template_name}",
        "priv/repo/migrations/#{file_name_with_timestamp}",
        assigns
      )
    end

    defp build_assigns(igniter, migration_name) do
      %{
        timestamp_type: :utc_datetime,
        migration_name: migration_name |> Macro.camelize()
      }
      |> Map.merge(igniter.assigns)
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
