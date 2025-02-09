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
  Returns the path to the current application.
  """
  def app_path, do: Path.join(["lib", to_string(app_name())])

  @doc """
  Returns the path to the current application's web module.
  """
  def app_web_path, do: app_path() <> "_web"

  @doc """
  Returns the module name of the given context.
  """
  def context_module_name(context_name), do: Module.concat([app_module_name(), context_name])

  @doc """
  Prepares an igniter with common assignments and configurations needed across all generators.
  Only runs once.
  """
  def prepare_igniter(%Igniter{assigns: %{initialized: true}} = igniter), do: igniter

  def prepare_igniter(igniter) do
    {_igniter, app_repo} = Igniter.Libs.Ecto.select_repo(igniter)

    igniter
    |> PhoenixAuthExtended.Info.validate_options()
    |> Igniter.assign(:options, Map.new(igniter.args.options))
    |> Igniter.assign(igniter.args.positional)
    |> Igniter.assign(:template_path, template_path())
    |> Igniter.assign(:app_name, app_name())
    |> Igniter.assign(:app_module_name, app_module_name())
    |> Igniter.assign(:app_repo, app_repo)
    |> Igniter.assign(:initialized, true)
    |> assign_context_module_name()
  end

  defp assign_context_module_name(
         %Igniter{args: %{positional: %{context_name: context_name}}} = igniter
       ) do
    Igniter.assign(igniter, :context_module_name, context_module_name(context_name))
  end

  defp assign_context_module_name(igniter), do: igniter

  @doc """
  Composes a task if the condition function returns true.
  """
  def compose_task_if(igniter, task_name, cond_func, argv \\ []) do
    case cond_func.(igniter) do
      true -> Igniter.compose_task(igniter, task_name, argv)
      _ -> igniter
    end
  end

  @doc """
  Copies a template to a destination path and assigns the given assigns.
  """
  def copy_template(igniter, template_file_path, destination_path) do
    assigns = Map.to_list(igniter.assigns)
    template_path = Path.join([template_path(), template_file_path])

    Igniter.copy_template(igniter, template_path, destination_path, assigns)
  end
end
