defmodule Mix.Tasks.Pax.Gen.Setup.Layout.Docs do
  @moduledoc false

  def short_doc do
    "Configures application layouts for authentication"
  end

  def example do
    "mix pax.gen.setup.layout"
  end

  def long_doc do
    """
    #{short_doc()}

    This task configures the application layouts for authentication by:
    * Adding authentication UI elements to the root layout
    * Setting up navigation for authenticated and guest users
    * Configuring user menu and authentication status display

    ## Layout Updates
    * Adds navigation bar with authentication status
    * Inserts conditional login/register links for guests
    * Adds user menu with settings and logout for authenticated users
    * Ensures proper responsive design for all elements

    ## Example

        #{example()}

    ## Modified Files

    The task will modify:
    * `lib/<app>_web/components/layouts/root.html.heex`
      - Adds authentication navigation bar
      - Configures user menu structure
      - Sets up responsive layout elements

    ## Layout Features

    The authentication navigation provides:
    * User email display when logged in
    * Settings and logout buttons for authenticated users
    * Register and login links for guests
    * Responsive design for all screen sizes
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Setup.Layout do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    import PhoenixAuthExtended
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
      igniter = prepare_igniter(igniter)

      with {:ok, layout_path} <- fetch_layout_path(igniter, "root"),
           content when is_binary(content) <- fetch_file_content(igniter, layout_path),
           {:ok, new_content} <- inject_after_body_tag(content, auth_menu_template()),
           updated_igniter <- inject_auth_menu(igniter, layout_path, new_content) do
        updated_igniter
      else
        :already_exists -> Igniter.add_notice(igniter, "A menu already exists in root.html.heex")
        _error -> Igniter.add_issue(igniter, warning_message())
      end
    end

    defp fetch_layout_path(igniter, layout_name) do
      web_module = Igniter.Libs.Phoenix.web_module(igniter) |> Macro.underscore()
      layout_file_name = "#{layout_name}.html.heex"

      path = Path.join(["lib", web_module, "components", "layouts", layout_file_name])

      if Igniter.exists?(igniter, path), do: {:ok, path}, else: :error
    end

    defp fetch_file_content(igniter, layout_path) do
      igniter
      |> Igniter.include_existing_file(layout_path)
      |> Map.get(:rewrite)
      |> Rewrite.source!(layout_path)
      |> Rewrite.Source.get(:content)
    end

    defp has_body_tag?(content), do: Regex.match?(~r/^(\s*)<body.*(\r\n|\n|$)/Um, content)
    defp already_exists?(content), do: String.contains?(content, "Log out")

    defp inject_auth_menu(igniter, file_path, new_content) do
      igniter
      |> Igniter.update_file(file_path, fn source ->
        dot_formatter = Rewrite.dot_formatter(igniter.rewrite)

        source
        |> Rewrite.Source.update(:content, new_content)
        |> Rewrite.Source.format!(dot_formatter: dot_formatter)
      end)
    end

    defp inject_after_body_tag(content, menu_items) do
      cond do
        not has_body_tag?(content) ->
          :missing_body_tag

        already_exists?(content) ->
          :already_exists

        true ->
          {:ok, Regex.replace(~r/(<body[^>]*>)/i, content, "\\1\n#{menu_items}", global: false)}
      end
    end

    defp warning_message do
      """
      Could not automatically inject the auth menu into root.html.heex.
      Please add the following menu items manually to your navigation:

      #{auth_menu_template()}
      """
    end

    defp auth_menu_template do
      """
      <ul class="relative z-10 flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end">
        <%= if @current_user do %>
          <li class="text-[0.8125rem] leading-6 text-zinc-900">
            {@current_user.email}
          </li>
          <li>
            <.link
              href={~p"/users/settings"}
              class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
            >
              Settings
            </.link>
          </li>
          <li>
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
            >
              Log out
            </.link>
          </li>
        <% else %>
          <li>
            <.link
              href={~p"/users/register"}
              class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
            >
              Register
            </.link>
          </li>
          <li>
            <.link
              href={~p"/users/log_in"}
              class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
            >
              Log in
            </.link>
          </li>
        <% end %>
      </ul>
      """
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Setup.Layout do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.setup.layout' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
