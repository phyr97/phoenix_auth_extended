defmodule Mix.Tasks.Pax.Gen.Base.Config.Docs do
  @moduledoc false

  def short_doc do
    "Configures the application for authentication"
  end

  def example do
    "mix pax.gen.base.config"
  end

  def long_doc do
    """
    #{short_doc()}

    This task updates the configuration files for authentication.
    When OAuth is enabled, it will configure the OAuth provider settings.

    ## OAuth Configuration

    If OAuth is enabled, the task will:
    * Add provider-specific configuration (client_id, client_secret)
    * Use built-in Assent strategies for supported providers
    * Add placeholder configuration for custom providers

    Supported OAuth providers:
    * Github (Assent.Strategy.Github)
    * Google (Assent.Strategy.Google)
    * Facebook (Assent.Strategy.Facebook)
    * Discord (Assent.Strategy.Discord)
    * Twitter (Assent.Strategy.Twitter)
    * And more...

    ## Example

        #{example()}

    ## Modified Files

    The task will modify:
    * `config/config.exs` - OAuth provider configuration
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Base.Config do
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
        positional: [],
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
      |> Igniter.Project.Config.configure("test.exs", :bcrypt_elixir, [:log_rounds], {:code, "1"})
      |> maybe_add_oauth_provider_config()
    end

    defp maybe_add_oauth_provider_config(%{assigns: %{auth_options: %{oauth: true}}} = igniter) do
      provider = get_in(igniter.assigns, [:auth_options, :oauth_provider])
      strategy = get_oauth_strategy(provider)

      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        :phoenix_auth_extended,
        [OAuthProviders, String.to_atom(provider)],
        {:code,
         Sourceror.parse_string!("""
          [
          #{strategy}
          client_id: System.get_env("#{String.upcase(provider)}_CLIENT_ID", "your_client_id"),
          client_secret: System.get_env("#{String.upcase(provider)}_CLIENT_SECRET", "your_secret")
         ]
         """)}
      )
    end

    defp maybe_add_oauth_provider_config(igniter), do: igniter

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
  defmodule Mix.Tasks.Pax.Gen.Base.Config do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Installiere `igniter` zur Verwendung"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      Die Task 'pax.gen.base.config' benötigt igniter. Bitte installiere igniter und versuche es erneut.

      Weitere Informationen unter: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
