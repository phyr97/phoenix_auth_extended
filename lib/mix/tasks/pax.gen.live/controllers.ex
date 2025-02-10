defmodule Mix.Tasks.Pax.Gen.Live.Controllers.Docs do
  @moduledoc false

  def short_doc do
    "Generates authentication controllers"
  end

  def example do
    "mix pax.gen.live.controllers Accounts User"
  end

  def long_doc do
    """
    #{short_doc()}

    This task generates the authentication controllers:

    * OAuth controller
      - Handles OAuth authentication flow
      - Manages OAuth callbacks
      - Integrates with identity context

    * Session controller
      - Manages user sessions
      - Handles login/logout
      - Processes authentication tokens

    ## Example

    ```bash
    #{example()}
    ```

    ## Generated Files

    The task will create:
    * `lib/your_app_web/controllers/oauth_controller.ex`
    * `lib/your_app_web/controllers/user_session_controller.ex`

    ## Arguments

    * `context_name` - The context module name (e.g., Accounts)
    * `entity_name` - The name of the entity (e.g., User)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Live.Controllers do
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
      |> generate_auth_module()
      |> generate_session_controller()
      |> then(fn igniter ->
        if igniter.assigns.options.oauth, do: generate_oauth_controller(igniter), else: igniter
      end)
    end

    defp generate_auth_module(igniter) do
      file_path = Path.join([app_web_path(), "auth.ex"])
      template = Path.join(["auth", "auth.eex"])

      copy_template(igniter, template, file_path)
    end

    defp generate_session_controller(igniter) do
      file_path = Path.join([app_web_path(), "controllers", "session_controller.ex"])
      template = Path.join(["controllers", "session_controller.eex"])

      copy_template(igniter, template, file_path)
    end

    defp generate_oauth_controller(igniter) do
      file_path = Path.join([app_web_path(), "controllers", "oauth_controller.ex"])
      template = Path.join(["controllers", "oauth_controller.eex"])

      copy_template(igniter, template, file_path)
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Live.Controllers do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.live.controllers' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
