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
    use PhoenixAuthExtended.Info

    import PhoenixAuthExtended

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> prepare_igniter()
      |> then(&Igniter.assign(&1, :entity_name_downcase, String.downcase(&1.assigns.entity_name)))
      |> generate_migrations()
    end

    defp generate_migrations(igniter) do
      igniter
      |> generate_migration(
        "entities.eex",
        "create_#{igniter.assigns.entity_name_downcase}_table",
        0
      )
      |> generate_migration(
        "entity_tokens.eex",
        "create_#{igniter.assigns.entity_name_downcase}_tokens_table",
        1
      )
      |> maybe_generate_passkey_migration()
    end

    defp maybe_generate_passkey_migration(%{assigns: %{options: %{passkey: true}}} = igniter) do
      generate_migration(
        igniter,
        "entity_keys.eex",
        "create_#{igniter.assigns.entity_name_downcase}_keys_table",
        2
      )
    end

    defp maybe_generate_passkey_migration(igniter), do: igniter

    defp generate_migration(igniter, template, migration_name, offset) do
      timestamp =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(offset, :second)
        |> Calendar.strftime("%Y%m%d%H%M%S")

      file_name_with_timestamp = "#{timestamp}_#{migration_name}.exs"
      template_path = Path.join(["migrations", template])

      igniter
      |> Igniter.assign(:migration_name, Macro.camelize(migration_name))
      |> copy_template(template_path, "priv/repo/migrations/#{file_name_with_timestamp}")
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
