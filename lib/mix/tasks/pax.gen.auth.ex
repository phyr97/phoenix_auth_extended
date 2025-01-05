defmodule Mix.Tasks.Pax.Gen.Auth.Docs do
  @moduledoc false

  def short_doc do
    "Generates authentication boilerplate for different authentication methods"
  end

  def example do
    "mix pax.gen.auth User --basic --basic-identifier email"
  end

  def long_doc do
    """
    #{short_doc()}

    Generates authentication boilerplate code based on selected authentication methods.
    If no authentication method is specified, basic authentication will be used by default.

    ## Authentication Methods

    * `--basic` - Email/Username + Password authentication
    * `--passkey` - Passwordless WebAuthn/FIDO authentication
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
    * `PROVIDER_SITE` (optional, for custom OAuth providers)

    ## Example

    ```bash
    #{example()}
    mix pax.gen.auth User --oauth --oauth-provider github --oauth-scopes "user:email,read:user"
    mix pax.gen.auth User --passkey
    mix pax.gen.auth User --basic --basic-identifier username --passkey
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
      required =
        argv
        |> parse_auth_flags()
        |> get_required_options()

      %Igniter.Mix.Task.Info{
        group: :phoenix_auth_extended,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        positional: [:entity_name],
        composes: ["pax.gen.base"],
        schema: @auth_options,
        defaults: [
          basic: !has_any_auth_flag?(argv),
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
        required: required
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter =
        igniter
        |> validate_auth_options()
        |> Igniter.compose_task("pax.gen.base", [igniter.args.positional[:entity_name]])

      IO.inspect(igniter.args)
      igniter
    end

    # Private helpers

    defp has_any_auth_flag?(argv) do
      {opts, _} =
        OptionParser.parse!(argv, strict: [basic: :boolean, passkey: :boolean, oauth: :boolean])

      Keyword.get(opts, :basic) || Keyword.get(opts, :passkey) || Keyword.get(opts, :oauth)
    end

    defp parse_auth_flags(argv) do
      {opts, _} = OptionParser.parse!(argv, strict: @auth_options)
      flags = Map.new(opts)

      if not Map.has_key?(flags, :basic) and
           not Map.has_key?(flags, :passkey) and
           not Map.has_key?(flags, :oauth) do
        Map.put(flags, :basic, true)
      else
        flags
      end
    end

    defp get_required_options(flags) do
      []
      |> add_basic_required(flags)
      |> add_oauth_required(flags)
    end

    defp add_basic_required(required, %{basic: true}) do
      [:basic_identifier | required]
    end

    defp add_basic_required(required, _), do: required

    defp add_oauth_required(required, %{oauth: true}) do
      [:oauth_provider, :oauth_scopes | required]
    end

    defp add_oauth_required(required, _), do: required

    defp validate_auth_options(igniter) do
      case igniter.args.options do
        %{basic_identifier: identifier} when identifier not in ["email", "username"] ->
          raise_invalid_option("basic-identifier must be either 'email' or 'username'")

        %{oauth_provider: provider, oauth_scopes: _scopes} = opts when not is_nil(provider) ->
          validate_oauth_options(opts)
          igniter

        _ ->
          igniter
      end
    end

    defp validate_oauth_options(%{oauth_provider: provider, oauth_scopes: scopes}) do
      unless provider =~ ~r/^[a-z0-9_]+$/ do
        raise_invalid_option(
          "oauth-provider must contain only lowercase letters, numbers, and underscores"
        )
      end

      unless scopes =~ ~r/^[a-zA-Z0-9:,_\s]+$/ do
        raise_invalid_option("oauth-scopes must be a comma-separated list of valid scope strings")
      end
    end

    @spec raise_invalid_option(String.t()) :: no_return()
    defp raise_invalid_option(message) do
      Mix.raise("Invalid option: #{message}")
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
