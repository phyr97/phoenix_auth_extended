defmodule Mix.Tasks.Pax.Gen.Setup.Config.Docs do
  @moduledoc false

  def short_doc do
    "Configures the application for authentication"
  end

  def example do
    "mix pax.gen.setup.config"
  end

  def long_doc do
    """
    #{short_doc()}

    This task updates the configuration files for authentication.
    When OAuth is enabled, it will configure the OAuth provider settings.

    ## Configuration Details

    * Sets up bcrypt configuration for password hashing
    * Configures OAuth providers when OAuth is enabled
    * Uses built-in Assent strategies for supported providers
    * Provides guidance for custom OAuth provider setup

    ## Example

        #{example()}

    ## Modified Files

    The task will modify:
    * `config/test.exs` - bcrypt configuration
    * `config/config.exs` - OAuth provider configuration (when OAuth enabled)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Setup.Config do
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

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> prepare_igniter()
      |> add_oauth_provider_config()

      # Currently no tests implemented
      # |> Igniter.Project.Config.configure("test.exs", :bcrypt_elixir, [:log_rounds], {:code, "1"})
    end

    defp add_oauth_provider_config(%{assigns: %{options: %{oauth: true}}} = igniter) do
      provider = get_in(igniter.assigns, [:options, :oauth_provider])

      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        :phoenix_auth_extended,
        [OAuthProviders, String.to_atom(provider)],
        {:code, oauth_config(provider)}
      )
    end

    defp add_oauth_provider_config(igniter), do: igniter

    defp oauth_config(provider) do
      strategy = get_oauth_strategy(provider)

      Sourceror.parse_string!("""
       [
       #{strategy}
       client_id: System.get_env("#{String.upcase(provider)}_CLIENT_ID", "your_client_id"),
       client_secret: System.get_env("#{String.upcase(provider)}_CLIENT_SECRET", "your_secret")
      ]
      """)
    end

    # Returns the appropriate Assent strategy module for known providers
    defp get_oauth_strategy(provider) do
      assent_strategy = Module.concat(Assent.Strategy, String.capitalize(provider))

      if Code.ensure_loaded?(assent_strategy) do
        """
        strategy: #{inspect(assent_strategy)},
        # Here can you find details to your strategy:
        # https://hexdocs.pm/assent/#{inspect(assent_strategy)}.html}
        """
      else
        """
        # TODO: Add your own custom strategy with Assent for #{provider}.
        # See: https://hexdocs.pm/assent/Assent.Strategy.html
        """
      end
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Setup.Config do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Installiere `igniter` zur Verwendung"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      Die Task 'pax.gen.setup.config' benötigt igniter. Bitte installiere igniter und versuche es erneut.

      Weitere Informationen unter: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
