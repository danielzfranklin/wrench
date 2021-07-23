defmodule Wrench.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def change do
    create table(:packages) do
      add :config_snippets, :map
      add :meta_other, :map
      add :docs_html_url, :string
      add :description, :string
      add :downloads_all, :integer
      add :downloads_day, :integer
      add :downloads_recent, :integer
      add :downloads_week, :integer
      add :html_url, :string
      add :hex_inserted_at, :utc_datetime
      add :latest_stable_version, :string
      add :latest_version, :string
      add :licenses, {:array, :string}
      add :links, :map
      add :name, :string
      add :repository, :string
      add :hex_updated_at, :utc_datetime
      add :api_url, :string

      timestamps()
    end

    create unique_index(:packages, [:name])
  end
end
