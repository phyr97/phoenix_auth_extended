defmodule Mix.Tasks.Pax.Gen.Schema.Schemas.Docs do
  @moduledoc false

  def short_doc do
    "Generates schema files for authentication"
  end

  def example do
    "mix pax.gen.schema.schemas Accounts User"
  end

  def long_doc do
    """
    #{short_doc()}

    This task generates the Ecto schema files for authentication:

    * Entity schema (e.g., User)
      - Basic fields for authentication
      - Email/Username field based on configuration
      - Password fields for basic auth
      - OAuth fields when enabled
      - Associations to tokens and keys

    * Entity token schema (e.g., UserToken)
      - Manages authentication tokens
      - Handles session tokens
      - Manages email confirmation tokens
      - Handles password reset tokens

    * Entity key schema (e.g., UserKey) - Only with passkey option
      - Stores WebAuthn/FIDO2 credentials
      - Manages passkey authentication
      - References the entity schema

    ## Example

    ```bash
    #{example()}
    ```

    ## Generated Files

    The task will create:
    * `lib/your_app/[context]/[entity].ex`
    * `lib/your_app/[context]/[entity]_token.ex`
    * `lib/your_app/[context]/[entity]_key.ex` (with passkey)

    ## Arguments

    * `context_name` - The context module name (e.g., Accounts)
    * `entity_name` - The name of the entity (e.g., User)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Schema.Schemas do
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
      entity_name = igniter.args.positional[:entity_name]

      igniter
      |> Igniter.assign(igniter.args.positional)
      |> assign_base_info()
      |> generate_schema("entity.eex", "#{entity_name}.ex")
      |> generate_schema("entity_token.eex", "#{entity_name}_token.ex")
      |> maybe_generate_key_schema()
    end

    defp maybe_generate_key_schema(%{assigns: %{auth_options: %{passkey: true}}} = igniter) do
      %{entity_name: entity_name} = igniter.assigns
      generate_schema(igniter, "entity_key.eex", "#{entity_name}_key.ex")
    end

    defp maybe_generate_key_schema(igniter), do: igniter

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
      |> Igniter.assign(:timestamp_type, :utc_datetime)
    end

    defp generate_schema(igniter, template_name, file_name) do
      assigns = igniter.assigns |> Map.to_list()

      context_path =
        Path.join([
          "lib",
          to_string(igniter.assigns.app),
          String.downcase(igniter.assigns.context_name)
        ])

      file_path = Path.join(context_path, file_name)

      igniter
      |> Igniter.copy_template(
        "priv/templates/schemas/#{template_name}",
        file_path,
        assigns
      )
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Schema.Schemas do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.setup.schemas' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
