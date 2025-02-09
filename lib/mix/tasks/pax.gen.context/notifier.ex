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
    use PhoenixAuthExtended.Info

    import PhoenixAuthExtended

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> prepare_igniter()
      |> generate_notifier()
    end

    defp generate_notifier(igniter) do
      file_name = "#{String.downcase(igniter.assigns.entity_name)}_notifier.ex"

      file_path =
        Path.join([app_path(), String.downcase(igniter.assigns.context_name), file_name])

      template_path = Path.join(["schemas", "entity_notifier.eex"])
      copy_template(igniter, template_path, file_path)
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
