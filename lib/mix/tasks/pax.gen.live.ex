defmodule Mix.Tasks.Pax.Gen.Live.Docs do
  @moduledoc false

  def short_doc do
    "Generates LiveView components for authentication"
  end

  def example do
    "mix pax.gen.live Accounts User"
  end

  def long_doc do
    """
    #{short_doc()}

    This task generates LiveView components for authentication:

    * Core Phoenix components
      - Adjusts form spacing
      - Adds button link component

    * Passkey components (when passkey enabled)
      - Guidance component for passkey explanation
      - Token form for authentication
      - Main passkey components module

    ## Example

    ```bash
    #{example()}
    ```

    ## Arguments

    * `context_name` - The context module name (e.g., Accounts)
    * `entity_name` - The name of the entity (e.g., User)

    ## Options

    This task inherits options from the auth generator:
    * `--passkey` - Generates additional passkey components
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Live do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    use PhoenixAuthExtended.Info,
      composes: [
        "pax.gen.live.components.phoenix",
        "pax.gen.live.components.passkey",
        "pax.gen.live.controllers"
      ]

    import PhoenixAuthExtended

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      argv = igniter.args.argv

      igniter
      |> prepare_igniter()
      |> Igniter.assign(:entity_name_downcase, String.downcase(igniter.assigns.entity_name))
      |> Igniter.compose_task("pax.gen.live.components.phoenix", argv)
      |> Igniter.compose_task("pax.gen.live.controllers", argv)
      |> generate_live_views()
      |> compose_task_if("pax.gen.live.components.passkey", & &1.assigns.options.passkey, argv)
    end

    defp generate_live_views(igniter) do
      live_views = [
        {"registration_live.eex", "registration_live.ex"},
        {"login_live.eex", "login_live.ex"},
        {"confirmation_live.eex", "confirmation_live.ex"},
        {"confirmation_instructions_live.eex", "confirmation_instructions_live.ex"},
        {"forgot_password_live.eex", "forgot_password_live.ex"},
        {"reset_password_live.eex", "reset_password_live.ex"},
        {"settings_live.eex", "settings_live.ex"},
        {"passkey_registration_live.eex", "passkey_registration_live.ex"}
      ]

      Enum.reduce(live_views, igniter, fn {template, file}, acc ->
        generate_live_view(acc, template, file)
      end)
    end

    defp generate_live_view(igniter, template_name, file_name) do
      web_path = Path.join([app_web_path(), "live"])
      file_path = Path.join(web_path, file_name)
      template = Path.join(["live", template_name])

      copy_template(igniter, template, file_path)
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Live do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.live' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
