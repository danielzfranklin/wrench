defmodule Wrench.Repo.Migrations.CreatePackageReleases do
  use Ecto.Migration

  def change do
    create table(:package_releases) do
      add :hex_etag, :string
      add :checksum, :string
      add :package_id, references(:packages)
      add :config_snippets, :map
      add :docs_html_url, :string
      add :downloads, :integer
      add :has_docs, :boolean, default: false
      add :html_url, :string
      add :hex_inserted_at, :utc_datetime
      add :app, :string
      add :build_tools, {:array, :string}
      add :elixir_version, :string
      add :api_package_url, :string
      add :meta_other, :map
      add :publisher, :map
      add :publisher_other, :map
      add :requirements, :map
      add :retirement, :map
      add :retirement_other, :map
      add :hex_updated_at, :utc_datetime
      add :api_url, :string
      add :version, :string

      timestamps()
    end

    create unique_index(:package_releases, [:package_id, :version])
  end
end
