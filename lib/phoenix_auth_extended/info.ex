defmodule PhoenixAuthExtended.Info do
  @doc """
  Returns the options for the generators.
  """
  def options do
    [
      basic: :boolean,
      passkey: :boolean,
      oauth: :boolean,
      basic_identifier: :string,
      oauth_provider: :string
    ]
  end

  @doc """
  Returns the default values for the generators.
  """
  def defaults do
    [
      basic: false,
      passkey: false,
      oauth: false,
      basic_identifier: "email"
    ]
  end

  @doc """
  Returns the required options for the generators.
  """
  def required_options(argv) do
    {opts, _} = OptionParser.parse!(argv, switches: options())

    []
    |> add_if(Keyword.get(opts, :basic), [:basic_identifier])
    |> add_if(Keyword.get(opts, :oauth), [:oauth_provider])
  end

  defp add_if(list, true, value), do: list ++ value
  defp add_if(list, _condition, _value), do: list

  @doc """
  Returns the positional arguments for the generators.
  """
  def positional_arguments, do: [:context_name, :entity_name]

  @doc """
  Returns the aliases for the generators.
  """
  def aliases do
    [
      b: :basic,
      p: :passkey,
      o: :oauth,
      i: :basic_identifier,
      s: :oauth_provider
    ]
  end

  def validate_options(igniter) do
    basic_identifier = Keyword.get(igniter.args.options, :basic_identifier)
    oauth_provider = Keyword.get(igniter.args.options, :oauth_provider)

    if basic_identifier != nil and basic_identifier not in ["email", "username"] do
      Mix.raise("Invalid option: basic-identifier must be either 'email' or 'username'")
    end

    if oauth_provider != nil and not is_binary(oauth_provider) do
      Mix.raise("Invalid option: oauth-provider not of type string")
    end

    igniter
  end

  defmacro __using__(opts) do
    quote do
      @impl Igniter.Mix.Task
      def info(argv, _composing_task) do
        %Igniter.Mix.Task.Info{
          group: :phoenix_auth_extended,
          adds_deps: [],
          installs: [],
          example: __MODULE__.Docs.example(),
          positional: PhoenixAuthExtended.Info.positional_arguments(),
          composes: unquote(Keyword.get(opts, :composes, [])),
          schema: PhoenixAuthExtended.Info.options(),
          defaults: PhoenixAuthExtended.Info.defaults(),
          aliases: PhoenixAuthExtended.Info.aliases(),
          required: PhoenixAuthExtended.Info.required_options(argv)
        }
      end
    end
  end
end
