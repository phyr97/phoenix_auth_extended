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
      igniter
      |> Igniter.assign(igniter.args.positional)
      |> assign_base_info()
      |> generate_auth_module()
      |> maybe_generate_oauth_controller()
      |> generate_session_controller()
    end

    defp assign_base_info(igniter) do
      app = Mix.Project.config() |> Keyword.fetch!(:app)
      app_camelized = to_string(app) |> Macro.camelize()
      app_module = Module.concat([app_camelized])
      app_web_module = Module.concat([app_module, "Web"])
      context_module = Module.concat([app_module, igniter.assigns.context_name])

      igniter
      |> Igniter.assign(:app, app)
      |> Igniter.assign(:app_camelized, app_camelized)
      |> Igniter.assign(:app_module, app_module)
      |> Igniter.assign(:app_web_module, app_web_module)
      |> Igniter.assign(:context_module, context_module)
    end

    defp generate_auth_module(igniter) do
      assigns = Map.to_list(igniter.assigns)
      web_path = Path.join(["lib", to_string(igniter.assigns.app) <> "_web"])
      file_path = Path.join(web_path, "user_auth.ex")

      igniter
      |> Igniter.copy_template(
        "priv/templates/auth/user_auth.eex",
        file_path,
        assigns
      )
    end

    defp maybe_generate_oauth_controller(%{assigns: %{auth_options: %{oauth: true}}} = igniter) do
      assigns = Map.to_list(igniter.assigns)
      web_path = Path.join(["lib", to_string(igniter.assigns.app) <> "_web"])
      file_path = Path.join([web_path, "controllers", "oauth_controller.ex"])

      igniter
      |> Igniter.copy_template(
        "priv/templates/controllers/oauth_controller.eex",
        file_path,
        assigns
      )
    end

    defp maybe_generate_oauth_controller(igniter), do: igniter

    defp generate_session_controller(igniter) do
      assigns = Map.to_list(igniter.assigns)
      web_path = Path.join(["lib", to_string(igniter.assigns.app) <> "_web"])
      file_path = Path.join([web_path, "controllers", "user_session_controller.ex"])

      igniter
      |> Igniter.copy_template(
        "priv/templates/controllers/user_session_controller.eex",
        file_path,
        assigns
      )
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
