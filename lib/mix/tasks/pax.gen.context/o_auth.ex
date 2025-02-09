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
    use PhoenixAuthExtended.Info

    import PhoenixAuthExtended

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> prepare_igniter()
      |> generate_oauth()
    end

    defp generate_oauth(igniter) do
      file_path =
        Path.join([app_path(), String.downcase(igniter.assigns.context_name), "oauth.ex"])

      template_path = Path.join(["schemas", "oauth.eex"])
      copy_template(igniter, template_path, file_path)
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
