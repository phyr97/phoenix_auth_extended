defmodule Mix.Tasks.Pax.Gen.Auth.Docs do
  @moduledoc false

  def short_doc do
    "Generates authentication boilerplate with multiple authentication methods"
  end

  def example do
    "mix pax.gen.auth Accounts User --basic --basic-identifier email"
  end

  def long_doc do
    """
    #{short_doc()}

    Generates authentication boilerplate code based on selected authentication methods.
    If no authentication method is specified, basic authentication will be used by default.

    ## Arguments

    * `context_name` - The context module name (e.g., Accounts)
    * `schema_name` - The schema module name (e.g., User)

    ## Authentication Methods

    * `--basic` - Email/Username + Password authentication
    * `--passkey` - Passwordless WebAuthn/FIDO2 authentication
    * `--oauth` - OAuth2 provider authentication

    ## Basic Authentication Options
    When using --basic, the following option is required:
    * `--basic-identifier` - Choose between 'email' or 'username' as identifier (default: email)

    ## OAuth Options
    When using --oauth, the following options are required:
    * `--oauth-provider` - Name of the OAuth provider (e.g., github, google)
    * `--oauth-scopes` - Comma-separated list of required OAuth scopes
    * `--oauth-callback-path` - Custom callback path (default: /auth/oauth/:provider/callback)

    Required environment variables will be generated with the provider name as prefix:
    * `PROVIDER_CLIENT_ID`
    * `PROVIDER_CLIENT_SECRET`

    ## Example

    ```bash
    #{example()}
    mix pax.gen.auth Accounts User --oauth --oauth-provider github --oauth-scopes "user:email,read:user"
    mix pax.gen.auth Accounts User --passkey
    mix pax.gen.auth Accounts User --basic --basic-identifier username --passkey
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Auth do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    use PhoenixAuthExtended.Info,
      composes: ["pax.gen.setup", "pax.gen.context", "pax.gen.live"]

    import PhoenixAuthExtended

    def igniter(igniter) do
      igniter
      |> prepare_igniter()
      |> Igniter.compose_task("pax.gen.setup")
      |> Igniter.compose_task("pax.gen.context")
      |> Igniter.compose_task("pax.gen.live")
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Auth do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.auth' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
