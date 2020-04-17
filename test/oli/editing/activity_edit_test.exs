defmodule Oli.ActivityEditingTest do
  use Oli.DataCase

  alias Oli.Editing.ActivityEditor
  alias Oli.Editing.ResourceEditor
  alias Oli.Editing.ResourceContext

  describe "activity editing" do

    setup do
      Seeder.base_project_with_resource()
        |> Seeder.add_objective("objective 1")
        |> Seeder.add_objective("objective 2")

    end

    test "create/4 creates an activity revision", %{author: author, project: project } do

      content = %{ "stem" => "Hey there" }
      {:ok, revision} = ActivityEditor.create(project.slug, "oli_multiple_choice", author, content)
      assert revision.content == %{ "stem" => "Hey there" }
    end

    test "can create and attach an activity to a resource", %{author: author, project: project, revision: revision } do

      content = %{ "stem" => "Hey there" }
      {:ok, %{slug: slug, activity_id: activity_id}} = ActivityEditor.create(project.slug, "oli_multiple_choice", author, content)

      # Verify that we can issue a resource edit that attaches the activity
      update = %{ "content" => [%{ "type" => "activity-reference", "id" => 1, "activitySlug" => slug, "purpose" => "none"}]}
      assert {:ok, updated_revision} =  ResourceEditor.edit(project.slug, revision.slug, author.email, update)

      # Verify that the slug was translated to the correct activity id
      activity_ref = hd(updated_revision.content)
      assert activity_id == Map.get(activity_ref, "activity_id")
      refute Map.has_key?(activity_ref, "activitySlug")


      # Now generate the resource editing context with this attached activity in place
      # so that we can verify that the activities, editorMap and content are all wired
      # together correctly
      {:ok, %ResourceContext{activities: activities, content: content, editorMap: editorMap}} = ResourceEditor.create_context(project.slug, revision.slug, author)

      activity_ref = hd(content)

      # verifies that the content entry has an activitySlug that references an activity map entry
      activity_slug = Map.get(activity_ref, "activitySlug")
      assert Map.has_key?(activities, activity_slug)

      # and that activity map entry has a type slug that references an editor map entry
      %{typeSlug: typeSlug} = Map.get(activities, activity_slug)
      assert Map.has_key?(editorMap, typeSlug)

    end

    test "activity context creation", %{author: author, project: project, revision: revision } do

      {:ok, %{slug: slug_1}} = ActivityEditor.create(project.slug, "oli_multiple_choice", author, %{ "stem" => "one" })

      # attach the activity
      update = %{ "content" => [%{ "type" => "activity-reference", "id" => 1, "activitySlug" => slug_1, "purpose" => "none"}]}
      assert {:ok, %{slug: revision_slug}} =  ResourceEditor.edit(project.slug, revision.slug, author.email, update)

      # create the activity context
      {:ok, context} = ActivityEditor.create_context(project.slug, revision_slug, slug_1, author)

      # verify all attributes of the editing context are what we expect
      assert context.activitySlug == slug_1
      assert context.model == %{ "stem" => "one" }
      assert context.previousActivity == nil
      assert context.nextActivity == nil
      assert context.friendlyName == "Multiple Choice"
      assert context.authoringElement == "oli-multiple-choice-authoring"
      assert context.authoringScript == "oli_multiple_choice_authoring.js"
      assert context.projectSlug == project.slug
      assert context.resourceSlug == revision_slug
      assert context.authorEmail == author.email
      assert length(context.allObjectives) == 2
      assert hd(context.allObjectives).title == "objective 1"
      assert hd(context.allObjectives).slug == "objective_1"

    end

    test "activity context previous and next siblings", %{author: author, project: project, revision: revision } do

      {:ok, %{slug: slug_1}} = ActivityEditor.create(project.slug, "oli_multiple_choice", author, %{ "stem" => "one" })
      {:ok, %{slug: slug_2}} = ActivityEditor.create(project.slug, "oli_multiple_choice", author, %{ "stem" => "two" })
      {:ok, %{slug: slug_3}} = ActivityEditor.create(project.slug, "oli_multiple_choice", author, %{ "stem" => "three" })

      # attach just one activity
      update = %{ "content" => [%{ "type" => "activity-reference", "id" => 1, "activitySlug" => slug_1, "purpose" => "none"}]}
      assert {:ok, _} =  ResourceEditor.edit(project.slug, revision.slug, author.email, update)

      # create the activity context
      {:ok, context} = ActivityEditor.create_context(project.slug, revision.slug, slug_1, author)

      # verify previous and next are nil
      assert context.previousActivity == nil
      assert context.nextActivity == nil

      # Attach two activities
      update = %{ "content" => [
        %{ "type" => "activity-reference", "id" => 1, "activitySlug" => slug_1, "purpose" => "none"},
        %{ "type" => "activity-reference", "id" => 2, "activitySlug" => slug_2, "purpose" => "none"}]}
      assert {:ok, _} =  ResourceEditor.edit(project.slug, revision.slug, author.email, update)

      # create the activity context
      {:ok, context} = ActivityEditor.create_context(project.slug, revision.slug, slug_1, author)

      # verify previous is nil and next is activity 2
      assert context.previousActivity == nil
      assert context.nextActivity.activitySlug == slug_2
      assert context.nextActivity.title == "Multiple Choice"
      assert context.nextActivity.friendlyName == "Multiple Choice"

      # create the activity context
      {:ok, context} = ActivityEditor.create_context(project.slug, revision.slug, slug_2, author)

      # verify previous is nil and previous is activity 1
      assert context.nextActivity == nil
      assert context.previousActivity.activitySlug == slug_1
      assert context.previousActivity.title == "Multiple Choice"
      assert context.previousActivity.friendlyName == "Multiple Choice"

      # Attach all three activities
      update = %{ "content" => [
        %{ "type" => "activity-reference", "id" => 1, "activitySlug" => slug_1, "purpose" => "none"},
        %{ "type" => "activity-reference", "id" => 2, "activitySlug" => slug_2, "purpose" => "none"},
        %{ "type" => "activity-reference", "id" => 3, "activitySlug" => slug_3, "purpose" => "none"}]}
      assert {:ok, _} =  ResourceEditor.edit(project.slug, revision.slug, author.email, update)

      {:ok, context} = ActivityEditor.create_context(project.slug, revision.slug, slug_1, author)
      assert context.previousActivity == nil
      assert context.nextActivity.activitySlug == slug_2

      {:ok, context} = ActivityEditor.create_context(project.slug, revision.slug, slug_2, author)
      assert context.previousActivity.activitySlug == slug_1
      assert context.nextActivity.activitySlug == slug_3

      {:ok, context} = ActivityEditor.create_context(project.slug, revision.slug, slug_3, author)
      assert context.previousActivity.activitySlug == slug_2
      assert context.nextActivity == nil

      # Attach all three activities, with interspersed content
      update = %{ "content" => [
        %{ "type" => "content", "id" => 1, "purpose" => "none", "children" => []},
        %{ "type" => "activity-reference", "id" => 2, "activitySlug" => slug_1, "purpose" => "none"},
        %{ "type" => "content", "id" => 3, "purpose" => "none", "children" => []},
        %{ "type" => "content", "id" => 4, "purpose" => "none", "children" => []},
        %{ "type" => "activity-reference", "id" => 5, "activitySlug" => slug_2, "purpose" => "none"},
        %{ "type" => "content", "id" => 6, "purpose" => "none", "children" => []},
        %{ "type" => "activity-reference", "id" => 7, "activitySlug" => slug_3, "purpose" => "none"},
        %{ "type" => "content", "id" => 8, "purpose" => "none", "children" => []}]}
      assert {:ok, _} =  ResourceEditor.edit(project.slug, revision.slug, author.email, update)

      {:ok, context} = ActivityEditor.create_context(project.slug, revision.slug, slug_1, author)
      assert context.previousActivity == nil
      assert context.nextActivity.activitySlug == slug_2

      {:ok, context} = ActivityEditor.create_context(project.slug, revision.slug, slug_2, author)
      assert context.previousActivity.activitySlug == slug_1
      assert context.nextActivity.activitySlug == slug_3

      {:ok, context} = ActivityEditor.create_context(project.slug, revision.slug, slug_3, author)
      assert context.previousActivity.activitySlug == slug_2
      assert context.nextActivity == nil

    end

    test "attaching an unknown activity to a resource fails", %{author: author, project: project, revision: revision } do

      update = %{ "content" => [%{ "type" => "activity-reference", "id" => 1, "activitySlug" => "missing", "purpose" => "none"}]}
      assert {:error, :not_found} =  ResourceEditor.edit(project.slug, revision.slug, author.email, update)

    end

  end

end
