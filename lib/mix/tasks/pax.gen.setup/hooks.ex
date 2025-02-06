defmodule Mix.Tasks.Pax.Gen.Setup.Hooks.Docs do
  @moduledoc false

  def short_doc do
    "Adds WebAuthn hooks to app.js"
  end

  def example do
    "mix pax.gen.setup.hooks --app-js-path=assets/custom/app.js"
  end

  def long_doc do
    """
    #{short_doc()}

    This task modifies the app.js file to add WebAuthn hooks for authentication.
    It reads the app.js file, validates its content, and adds the necessary imports
    and hooks to the LiveSocket configuration:

    * Adds import for WebAuthn components
    * Extends LiveSocket hooks configuration with:
      - SupportHook - Checks WebAuthn browser support
      - AuthenticationHook - Handles WebAuthn authentication
      - RegistrationHook - Handles WebAuthn registration

    ## Example

    ```bash
    #{example()}
    ```

    ## Modified Files

    The task will modify:
    * `assets/js/app.js` (default)
    * Or a custom path specified via --app-js-path

    ## Options

    * `--app-js-path` - Custom path to app.js (default: "assets/js/app.js")

    ## Requirements

    * The specified JavaScript file must exist and have a .js extension
    * The file must contain a LiveSocket configuration to be extended
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Setup.Hooks do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task
    alias IgniterJs.Parsers.Javascript.Parser

    @default_app_js_path Path.join(["assets", "js", "app.js"])
    @webauthn_hooks ["SupportHook", "AuthenticationHook", "RegistrationHook"]
    @webauthn_import "import {\n  SupportHook,\n  AuthenticationHook,\n  RegistrationHook,\n} from \"webauthn_components\";"

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_auth_extended,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        positional: [],
        composes: [],
        schema: [
          app_js_path: :string
        ],
        defaults: [
          app_js_path: @default_app_js_path
        ],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      app_js_path = igniter.args.options[:app_js_path]

      with {:ok, content} <- IgniterJs.Helpers.read_and_validate_file(app_js_path),
           {:ok, _, content} <- Parser.insert_imports(content, @webauthn_import, :content),
           {:ok, _, content} <- Parser.extend_hook_object(content, @webauthn_hooks, :content) do
        Igniter.create_new_file(igniter, app_js_path, content, on_exists: :overwrite)
      else
        {:error, _function, error} -> Mix.raise("Failed to modify app.js: #{error}")
        {:error, error} -> Mix.raise("Could not read app.js: #{error}")
      end
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Setup.Hooks do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.setup.hooks' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
