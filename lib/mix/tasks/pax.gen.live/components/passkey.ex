defmodule Mix.Tasks.Pax.Gen.Live.Components.Passkey.Docs do
  @moduledoc false

  def short_doc do
    "Generates passkey components for authentication"
  end

  def example do
    "mix pax.gen.live.components.passkey Accounts User"
  end

  def long_doc do
    """
    #{short_doc()}

    This task generates the passkey components for authentication:

    * Main passkey components module
    * Guidance component for passkey explanation
    * Token form for authentication

    ## Example

    ```bash
    #{example()}
    ```

    ## Arguments

    * `context_name` - The context module name (e.g., Accounts)
    * `entity_name` - The name of the entity (e.g., User)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Live.Components.Passkey do
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
      |> generate_passkey_components()
    end

    defp generate_passkey_components(igniter) do
      template = Path.join(["components", "passkey_components.eex"])
      file_path = Path.join([app_web_path(), "components", "passkey_components.ex"])

      copy_template(igniter, template, file_path)
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Live.Components.Passkey do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.live.components.passkey' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
