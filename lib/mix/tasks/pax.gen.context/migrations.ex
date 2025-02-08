defmodule Mix.Tasks.Pax.Gen.Context.Migrations.Docs do
  @moduledoc false

  def short_doc do
    "Generates database migrations for authentication"
  end

  def example do
    "mix pax.gen.setup.migrations User"
  end

  def long_doc do
    """
    #{short_doc()}

    This task generates the necessary database migrations for authentication.
    It creates the base tables required for entity management and authentication:

    * Entity table (e.g., users)
      - Stores the main entity information
      - Uses binary_id (ULID) as primary key
      - Includes timestamps

    * Entity tokens table (e.g., user_tokens)
      - Manages authentication tokens
      - Handles email confirmation
      - Supports password reset
      - References the entity table

    * Entity keys table (e.g., user_keys) - Only with passkey option
      - Stores WebAuthn/FIDO2 credentials
      - Manages passkey authentication
      - References the entity table

    ## Example

    ```bash
    #{example()}
    ```

    ## Generated Files

    The task will create the following migration files:
    * `priv/repo/migrations/[timestamp]_create_[entity]_table.exs`
    * `priv/repo/migrations/[timestamp]_create_[entity]_tokens_table.exs`
    * `priv/repo/migrations/[timestamp]_create_[entity]_keys_table.exs` (with passkey)

    ## Arguments

    * `entity_name` - The name of the entity (e.g., User)

    ## Options

    This task inherits options from the parent auth generator:
    * `--passkey` - Generates additional migration for WebAuthn/FIDO2 keys
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Context.Migrations do
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
        positional: [:entity_name],
        composes: [],
        schema: [],
        defaults: [],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      entity_name = igniter.args.positional[:entity_name]

      igniter
      |> prepare_igniter()
      |> Igniter.assign(:entity_name, entity_name)
      |> assign_base_info()
      |> generate_migration("entities.eex", "create_#{entity_name}_table")
      |> generate_migration("entity_tokens.eex", "create_#{entity_name}_tokens_table")
      |> maybe_generate_passkey_migration()
    end

    defp maybe_generate_passkey_migration(%{assigns: %{auth_options: %{passkey: true}}} = igniter) do
      entity_name = igniter.assigns.entity_name
      generate_migration(igniter, "entity_keys.eex", "create_#{entity_name}_keys_table")
    end

    defp maybe_generate_passkey_migration(igniter), do: igniter

    defp assign_base_info(igniter) do
      app = Mix.Project.config() |> Keyword.fetch!(:app)
      app_module_name = to_string(app) |> Macro.camelize()
      app_repo = Module.concat([app_module_name, "Repo"])

      igniter
      |> Igniter.assign(:app, app)
      |> Igniter.assign(:app_module_name, app_module_name)
      |> Igniter.assign(:app_repo, app_repo)
    end

    defp generate_migration(igniter, template, migration_name) do
      timestamp = NaiveDateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")
      file_name_with_timestamp = "#{timestamp}_#{migration_name}.exs"
      assigns = build_assigns(igniter, migration_name)

      template_path = Path.join([igniter.assigns.template_path, "migrations", template])

      Igniter.copy_template(
        igniter,
        template_path,
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
      |> Map.to_list()
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Context.Migrations do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.setup.migrations' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
