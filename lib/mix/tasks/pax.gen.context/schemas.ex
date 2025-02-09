defmodule Mix.Tasks.Pax.Gen.Context.Schemas.Docs do
  @moduledoc false

  def short_doc do
    "Generates schema files for authentication"
  end

  def example do
    "mix pax.gen.context.schemas Accounts User"
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
  defmodule Mix.Tasks.Pax.Gen.Context.Schemas do
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
      |> generate_schemas()
    end

    def generate_schemas(igniter) do
      igniter
      |> generate_schema("entity.eex", "#{igniter.assigns.entity_name}.ex")
      |> generate_schema("entity_token.eex", "#{igniter.assigns.entity_name}_token.ex")
      |> maybe_generate_key_schema()
      |> maybe_generate_validation()
    end

    defp maybe_generate_key_schema(%{assigns: %{options: %{passkey: true}}} = igniter) do
      generate_schema(igniter, "entity_key.eex", "#{igniter.assigns.entity_name}_key.ex")
    end

    defp maybe_generate_key_schema(igniter), do: igniter

    defp maybe_generate_validation(igniter) do
      if igniter.assigns.options.basic or igniter.assigns.options.basic_identifier == "email" do
        generate_schema(igniter, "validation.eex", "validation.ex")
      else
        igniter
      end
    end

    defp generate_schema(igniter, template, file_name) do
      file_path =
        Path.join([app_path(), String.downcase(igniter.assigns.context_name), file_name])

      template_path = Path.join(["schemas", template])
      copy_template(igniter, template_path, file_path)
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Context.Schemas do
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
