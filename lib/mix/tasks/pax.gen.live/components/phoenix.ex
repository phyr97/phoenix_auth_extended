defmodule Mix.Tasks.Pax.Gen.Live.Components.Phoenix.Docs do
  @moduledoc false

  def short_doc do
    "Configures core Phoenix components for authentication"
  end

  def example do
    "mix pax.gen.live.components.phoenix"
  end

  def long_doc do
    """
    #{short_doc()}

    This task configures the core components for authentication:

    * Adjusts simple_form spacing from space-y-8 to space-y-4
    * Adds button_link component when using OAuth or Passkey authentication
      - Provides a link styled as a button
      - Used for OAuth provider links and Passkey registration

    ## Example

        #{example()}

    ## Modified Files

    The task will modify:
    * `lib/<app>_web/components/core_components.ex`
      - Updates simple_form spacing
      - Adds button_link component (when using OAuth/Passkey)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pax.Gen.Live.Components.Phoenix do
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
      web_module = Igniter.Libs.Phoenix.web_module(igniter)
      core_components_module = Module.safe_concat([web_module, "CoreComponents"])

      igniter
      |> prepare_igniter()
      |> adjust_spacing_for_simple_form(core_components_module)
      |> then(fn igniter ->
        if igniter.assigns.options.passkey or igniter.assigns.options.oauth,
          do: add_button_link_component(igniter, core_components_module),
          else: igniter
      end)
    end

    defp adjust_spacing_for_simple_form(igniter, module) do
      case Igniter.Project.Module.find_and_update_module(igniter, module, &update_spacing/1) do
        {:ok, igniter} -> igniter
        {:error, igniter} -> igniter
      end
    end

    defp update_spacing(zipper) do
      pattern =
        """
        def simple_form(assigns) do
           __cursor__()
        end
        """

      case Sourceror.Zipper.search_pattern(zipper, pattern) do
        nil ->
          :spacing_not_found

        zipper ->
          node = Sourceror.Zipper.node(zipper)
          [{:<<>>, meta, [content]}, modifiers] = elem(node, 2)
          updated_content = String.replace(content, "space-y-8", "space-y-4")
          updated_node = {:sigil_H, elem(node, 1), [{:<<>>, meta, [updated_content]}, modifiers]}
          zipper = Sourceror.Zipper.replace(zipper, updated_node)
          {:ok, zipper}
      end
    end

    defp add_button_link_component(igniter, module) do
      case Igniter.Project.Module.find_and_update_module(
             igniter,
             module,
             &find_and_insert_button_link/1
           ) do
        {:ok, igniter} -> igniter
        {:error, igniter} -> igniter
      end
    end

    defp find_and_insert_button_link(zipper) do
      with :error <- Igniter.Code.Function.move_to_def(zipper, :button_link, 1),
           {:ok, zipper} <- Igniter.Code.Function.move_to_def(zipper, :button, 1) do
        {:ok, Igniter.Code.Common.add_code(zipper, button_link_code(), placement: :after)}
      else
        {:ok, zipper} ->
          {:ok, zipper}

        :error ->
          {:ok, Igniter.Code.Common.add_code(zipper, button_link_code(), placement: :after)}
      end
    end

    defp button_link_code do
      """
        @doc \"\"\"
        Renders a link that looks like a button.

        ## Examples

            <.button_link navigate={~p"/some/path"}>Next</.button_link>
            <.button_link href="https://example.com" class="ml-2">External link</.button_link>
        \"\"\"
        attr :navigate, :string, default: nil
        attr :href, :string, default: nil
        attr :class, :string, default: nil
        attr :rest, :global
        slot :inner_block, required: true

        def button_link(assigns) do
          ~H\"\"\"
          <.link
            navigate={@navigate}
            href={@href}
            class={[
              "rounded-lg hover:bg-zinc-100 py-2 px-3 border border-zinc-900",
              "text-sm font-semibold leading-6 text-zinc-900 active:text-zinc-700",
              "flex items-center justify-center gap-1",
              @class
            ]}
            {@rest}
          >
            {render_slot(@inner_block)}
          </.link>
          \"\"\"
        end
      """
    end
  end
else
  defmodule Mix.Tasks.Pax.Gen.Live.Components.Phoenix do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'pax.gen.live.components.phoenix' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
