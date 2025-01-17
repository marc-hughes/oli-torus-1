defmodule OliWeb.Resources.PagesView do
  use Surface.LiveView, layout: {OliWeb.LayoutView, "live.html"}
  use OliWeb.Common.Modal

  import OliWeb.DelegatedEvents
  import OliWeb.Common.Params
  import Oli.Authoring.Editing.Utils
  alias Oli.Accounts
  alias OliWeb.Router.Helpers, as: Routes
  alias OliWeb.Common.{TextSearch, PagedTable, Breadcrumb, FilterBox}
  alias Oli.Resources.PageBrowse
  alias OliWeb.Common.Table.SortableTableModel
  alias Oli.Resources.PageBrowseOptions
  alias OliWeb.Common.SessionContext
  alias OliWeb.Resources.PagesTableModel
  alias Oli.Repo.{Paging, Sorting}

  data title, :string, default: "All Pages"
  data project, :any
  data breadcrumbs, :list
  data author, :any
  data pages, :list

  @limit 25

  defp limit, do: @limit
  defp graded_opts, do: [{true, "Graded"}, {false, "Practice"}]
  defp type_opts, do: [{true, "Regular"}, {false, "Adaptive"}]

  @default_options %PageBrowseOptions{
    basic: nil,
    graded: nil,
    deleted: false,
    text_search: nil
  }

  def breadcrumb(project) do
    [
      Breadcrumb.new(%{
        full_title: "Project Overview",
        link: Routes.project_path(OliWeb.Endpoint, :overview, project.slug)
      }),
      Breadcrumb.new(%{full_title: "All Pages"})
    ]
  end

  def mount(
        %{"project_id" => project_slug},
        %{"current_author_id" => author_id} = session,
        socket
      ) do
    socket =
      with {:ok, author} <- Accounts.get_author(author_id) |> trap_nil(),
           {:ok, project} <- Oli.Authoring.Course.get_project_by_slug(project_slug) |> trap_nil(),
           {:ok} <- authorize_user(author, project) do
        context = SessionContext.init(session)

        pages =
          PageBrowse.browse_pages(
            project,
            %Paging{offset: 0, limit: @limit},
            %Sorting{direction: :asc, field: :title},
            @default_options
          )

        total_count = determine_total(pages)
        {:ok, table_model} = PagesTableModel.new(pages, project, context)

        assign(socket,
          modal: nil,
          context: context,
          breadcrumbs: breadcrumb(project),
          project: project,
          author: author,
          total_count: total_count,
          table_model: table_model,
          options: @default_options
        )
      else
        _ ->
          socket
          |> put_flash(:info, "You do not have permission to access this course project")
          |> push_redirect(to: Routes.live_path(OliWeb.Endpoint, IndexView))
      end

    {:ok, socket}
  end

  defp determine_total(projects) do
    case(projects) do
      [] -> 0
      [hd | _] -> hd.total_count
    end
  end

  def handle_params(params, _, socket) do
    table_model =
      SortableTableModel.update_from_params(
        socket.assigns.table_model,
        params
      )

    offset = get_int_param(params, "offset", 0)

    options = %PageBrowseOptions{
      text_search: get_param(params, "text_search", ""),
      deleted: false,
      graded: get_boolean_param(params, "graded", nil),
      basic: get_boolean_param(params, "basic", nil)
    }

    pages =
      PageBrowse.browse_pages(
        socket.assigns.project,
        %Paging{offset: offset, limit: @limit},
        %Sorting{direction: table_model.sort_order, field: table_model.sort_by_spec.name},
        options
      )

    table_model = Map.put(table_model, :rows, pages)
    total_count = determine_total(pages)

    {:noreply,
     assign(socket,
       offset: offset,
       table_model: table_model,
       total_count: total_count,
       options: options
     )}
  end

  def render(assigns) do
    ~F"""
    {render_modal(assigns)}
    <div>

      <FilterBox
        card_header_text="Browse All Pages"
        card_body_text=""
        table_model={@table_model}
        show_sort={false}
        show_more_opts={true}>
        <TextSearch id="text-search" text={@options.text_search}/>

        <:extra_opts>

          <form :on-change="change_graded" class="d-flex">
            <select name="graded" id="select_graded" class="custom-select custom-select mr-2">
              <option value="" selected>Grading Type</option>
              {#for {value, str} <- graded_opts()}
                <option value={Kernel.to_string(value)} selected={@options.graded == value}>{str}</option>
              {/for}
            </select>
          </form>

          <form :on-change="change_type" class="d-flex">
            <select name="type" id="select_type" class="custom-select custom-select mr-2">
              <option value="" selected>Page Type</option>
              {#for {value, str} <- type_opts()}
                <option value={Kernel.to_string(value)} selected={@options.basic == value}>{str}</option>
              {/for}
            </select>
          </form>
        </:extra_opts>
      </FilterBox>

      <div class="mb-3"/>

      <PagedTable
        filter={@options.text_search}
        table_model={@table_model}
        total_count={@total_count}
        offset={@offset}
        limit={limit()}/>
    </div>
    """
  end

  def patch_with(socket, changes) do
    {:noreply,
     push_patch(socket,
       to:
         Routes.live_path(
           socket,
           __MODULE__,
           socket.assigns.project.slug,
           Map.merge(
             %{
               sort_by: socket.assigns.table_model.sort_by_spec.name,
               sort_order: socket.assigns.table_model.sort_order,
               offset: socket.assigns.offset,
               text_search: socket.assigns.options.text_search,
               basic: socket.assigns.options.basic,
               graded: socket.assigns.options.graded
             },
             changes
           )
         ),
       replace: true
     )}
  end

  def handle_event("change_graded", %{"graded" => graded}, socket) do
    patch_with(socket, %{graded: graded})
  end

  def handle_event("change_type", %{"type" => basic}, socket) do
    patch_with(socket, %{basic: basic})
  end

  def handle_event("show_delete_modal", %{"slug" => slug}, socket) do
    %{project: project, author: author} = socket.assigns

    revision = Enum.find(socket.assigns.table_model.rows, fn r -> r.slug == slug end)

    container =
      case PageBrowse.find_parent_container(project, revision) do
        [] -> nil
        [container] -> container
      end

    assigns = %{
      id: "delete_#{revision.slug}",
      redirect_url:
        Routes.live_path(
          socket,
          __MODULE__,
          socket.assigns.project.slug,
          %{
            sort_by: socket.assigns.table_model.sort_by_spec.name,
            sort_order: socket.assigns.table_model.sort_order,
            offset: socket.assigns.offset,
            text_search: socket.assigns.options.text_search
          }
        ),
      revision: revision,
      container: container,
      project: project,
      author: author
    }

    {:noreply,
     assign(socket,
       modal: %{component: OliWeb.Curriculum.DeleteModal, assigns: assigns}
     )}
  end

  def handle_event("show_options_modal", %{"slug" => slug}, socket) do
    %{project: project} = socket.assigns

    assigns = %{
      id: "options_#{slug}",
      redirect_url:
        Routes.live_path(
          socket,
          __MODULE__,
          socket.assigns.project.slug,
          %{
            sort_by: socket.assigns.table_model.sort_by_spec.name,
            sort_order: socket.assigns.table_model.sort_order,
            offset: socket.assigns.offset,
            text_search: socket.assigns.options.text_search
          }
        ),
      revision: Enum.find(socket.assigns.table_model.rows, fn r -> r.slug == slug end),
      project: project
    }

    {:noreply,
     assign(socket,
       modal: %{component: OliWeb.Curriculum.OptionsModal, assigns: assigns}
     )}
  end

  def handle_event("duplicate_page", %{"id" => page_id}, socket) do
    %{project: project, author: author} = socket.assigns
    page_id = String.to_integer(page_id)
    revision = Enum.find(socket.assigns.table_model.rows, fn r -> r.id == page_id end)

    original_page = Map.from_struct(revision)

    new_page_attrs =
      original_page
      |> Map.drop([:slug, :inserted_at, :updated_at, :resource_id, :resource])
      |> Map.put(:title, "Copy of #{original_page.title}")
      |> Map.put(:content, nil)
      |> Map.put(:author_id, author.id)

    Oli.Repo.transaction(fn ->
      with {:ok, %{revision: revision}} <-
             Oli.Authoring.Course.create_and_attach_resource(project, new_page_attrs),
           {:ok, _} <- Oli.Publishing.ChangeTracker.track_revision(project.slug, revision),
           {:ok, model_duplicated_activities} <-
             Oli.Authoring.Editing.ContainerEditor.deep_copy_activities(
               original_page.content["model"],
               project.slug,
               author
             ),
           new_content <- %{
             original_page.content
             | "model" => Enum.reverse(model_duplicated_activities)
           },
           {:ok, updated_revision} <-
             Oli.Resources.update_revision(revision, %{content: new_content}) do
        updated_revision
      else
        {:error, e} -> Oli.Repo.rollback(e)
      end
    end)

    patch_with(socket, %{})
  end

  def handle_event(event, params, socket) do
    {event, params, socket, &__MODULE__.patch_with/2}
    |> delegate_to([
      &TextSearch.handle_delegated/4,
      &PagedTable.handle_delegated/4
    ])
  end
end
