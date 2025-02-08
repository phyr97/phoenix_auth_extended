defmodule PhoenixAuthExtended do
  @doc """
  Returns the absolute path to the phoenix_auth_extended dependency.
  """
  def pax_path, do: Application.app_dir(:phoenix_auth_extended)

  @doc """
  Returns the absolute path to the phoenix_auth_extended templates.
  """
  def template_path, do: Path.join([pax_path(), "priv", "templates"])

  @doc """
  Returns the name of the current application.
  """
  def app_name, do: Mix.Project.config() |> Keyword.fetch!(:app)

  @doc """
  Returns the module name of the current application.
  """
  def app_module_name, do: app_name() |> to_string() |> Macro.camelize()

  @doc """
  Prepares an igniter with common assignments and configurations needed across all generators.
  This function should be called at the beginning of each generator's igniter function.

  ## Example

      def igniter(igniter) do
        igniter
        |> PhoenixAuthExtended.prepare_igniter()
        |> your_generator_specific_logic()
      end

  """
  def prepare_igniter(igniter) do
    {_igniter, app_repo} = Igniter.Libs.Ecto.select_repo(igniter)

    igniter
    |> PhoenixAuthExtended.Info.validate_options()
    |> Igniter.assign(:options, igniter.args.options)
    |> assign_positional_arguments()
    |> Igniter.assign(:template_path, template_path())
    |> Igniter.assign(:app_name, app_name())
    |> Igniter.assign(:app_module_name, app_module_name())
    |> Igniter.assign(:app_repo, app_repo)
  end

  defp assign_positional_arguments(igniter) do
    PhoenixAuthExtended.Info.positional_arguments()
    |> Enum.reduce(igniter, &Igniter.assign(&2, &1, igniter.args.positional[&1]))
  end

  def copy_template(igniter, template_path, destination_path, assigns \\ []) do
    Igniter.copy_template(igniter, template_path, destination_path, assigns)
  end
end
