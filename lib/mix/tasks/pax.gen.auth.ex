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

    @auth_options [
      basic: :boolean,
      passkey: :boolean,
      oauth: :boolean,
      basic_identifier: :string,
      oauth_provider: :string,
      oauth_scopes: :string,
      oauth_callback_path: :string
    ]

    @impl Igniter.Mix.Task
    def info(argv, _composing_task) do
      {opts, _} = OptionParser.parse!(argv, switches: @auth_options)

      %Igniter.Mix.Task.Info{
        group: :phoenix_auth_extended,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        positional: [:context_name, :entity_name],
        composes: ["pax.gen.setup"],
        schema: @auth_options,
        defaults: [
          basic: Enum.empty?(opts),
          passkey: false,
          oauth: false,
          basic_identifier: "email",
          oauth_callback_path: "/auth/oauth/:provider/callback"
        ],
        aliases: [
          b: :basic,
          p: :passkey,
          o: :oauth
        ],
        required: required_options(opts)
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> validate_options()
      |> Igniter.assign(:auth_options, igniter.args.options |> Map.new())
      |> Igniter.compose_task("pax.gen.setup", igniter.args.argv)
      |> Igniter.compose_task("pax.gen.context", igniter.args.argv)
      |> Igniter.compose_task("pax.gen.live", igniter.args.argv)
    end

    # Private helpers

    defp required_options(options) do
      []
      |> add_if(Keyword.get(options, :basic), [:basic_identifier])
      |> add_if(Keyword.get(options, :oauth), [:oauth_provider, :oauth_scopes])
    end

    defp add_if(list, true, value), do: list ++ value
    defp add_if(list, _condition, _value), do: list

    defp validate_options(igniter) do
      if Keyword.get(igniter.args.options, :basic_identifier) not in ["email", "username"] do
        Mix.raise("Invalid option: basic-identifier must be either 'email' or 'username'")
      end

      igniter
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
