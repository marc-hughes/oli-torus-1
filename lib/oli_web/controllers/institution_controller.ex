defmodule OliWeb.InstitutionController do
  use OliWeb, :controller

  alias Oli.Accounts
  alias Oli.Accounts.Institution

  import Oli.CountryCodes
  import Oli.Timezones

  def index(conn, _params) do
    institutions = Accounts.list_institutions()
    render(conn, "index.html", institutions: institutions)
  end

  def new(conn, _params) do
    changeset = Accounts.change_institution(%Institution{})
    render(conn, "new.html", changeset: changeset, country_codes: list_country_codes(), timezones: list_timezones())
  end

  def create(conn, %{"institution" => institution_params}) do
    case Accounts.create_institution(institution_params) do
      {:ok, _institution} ->
        conn
        |> put_flash(:info, "Institution created successfully.")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    institution = Accounts.get_institution!(id)
    render(conn, "show.html", institution: institution)
  end

  def edit(conn, %{"id" => id}) do
    institution = Accounts.get_institution!(id)
    changeset = Accounts.change_institution(institution)
    render(conn, "edit.html", institution: institution, changeset: changeset)
  end

  def update(conn, %{"id" => id, "institution" => institution_params}) do
    institution = Accounts.get_institution!(id)

    case Accounts.update_institution(institution, institution_params) do
      {:ok, institution} ->
        conn
        |> put_flash(:info, "Institution updated successfully.")
        |> redirect(to: Routes.institution_path(conn, :show, institution))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", institution: institution, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    institution = Accounts.get_institution!(id)
    {:ok, _institution} = Accounts.delete_institution(institution)

    conn
    |> put_flash(:info, "Institution deleted successfully.")
    |> redirect(to: Routes.institution_path(conn, :index))
  end
end
