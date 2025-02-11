defmodule Mix.Tasks.Pax.Gen.Setup.Dependencies.Docs do
  @moduledoc false

  def short_doc do
    "Adds required dependencies for authentication"
  end

  def example do
    "mix pax.gen.setup.dependencies"
  end

  def long_doc do
    """
    #{short_doc()}

    This task adds the required dependencies to mix.exs based on the selected authentication methods:

    ## Basic Auth Dependencies (when basic auth enabled)
    * bcrypt_elixir - Password hashing

    ## OAuth Dependencies (when OAuth enabled)
    * assent - OAuth/OAuth2 authentication
    * req - HTTP client for OAuth requests

    ## Passkey Dependencies (when Passkey enabled)
    * webauthn_components - WebAuthn/FIDO2 components for LiveView

    ## Example

        #{example()}

    ## Modified Files

    The task will modify:
    * `mix.exs` - Project dependencies
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Setup.Dependencies do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    import PhoenixAuthExtended

    alias PhoenixAuthExtended.Info

    @impl Igniter.Mix.Task
    def info(argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_auth_extended,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        positional: [],
        composes: [],
        schema: Info.options(),
        defaults: Info.defaults(),
        aliases: Info.aliases(),
        required: Info.required_options(argv)
      }
    end

    @basic_deps [
      {:bcrypt_elixir, "~> 3.0"}
    ]

    @oauth_deps [
      {:assent, "~> 0.3.0"},
      {:req, "~> 0.5.8"}
    ]

    @passkey_deps [
      {:webauthn_components, "~> 0.8.0"}
    ]

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> prepare_igniter()
      |> maybe_add_dependencies(:basic, @basic_deps)
      |> maybe_add_dependencies(:oauth, @oauth_deps)
      |> maybe_add_dependencies(:passkey, @passkey_deps)
    end

    defp maybe_add_dependencies(igniter, auth_type, deps) do
      if get_in(igniter.assigns, [:options, auth_type]) do
        Enum.reduce(deps, igniter, &Igniter.Project.Deps.add_dep(&2, &1))
      else
        igniter
      end
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Setup.Dependencies do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.setup.dependencies' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
