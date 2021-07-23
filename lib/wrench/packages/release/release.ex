defmodule Wrench.Packages.Release do
  use Ecto.Schema
  import Ecto.Changeset
  alias Wrench.Packages.Package
  alias Wrench.Packages.ConfigSnippet
  alias Wrench.Packages.Release

  schema "package_releases" do
    field :hex_etag, :string
    field :checksum, :string
    belongs_to :package, Package
    embeds_many :config_snippets, ConfigSnippet, on_replace: :delete
    field :docs_html_url, :string
    field :downloads, :integer
    field :has_docs, :boolean, default: false
    field :html_url, :string
    field :hex_inserted_at, :utc_datetime
    field :app, :string
    field :build_tools, {:array, :string}
    field :elixir_version, :string
    field :meta_other, :map
    field :api_package_url, :string
    embeds_one :publisher, Release.Publisher
    field :publisher_other, :map
    embeds_many :requirements, Release.Requirement
    embeds_one :retirement, Release.Retirement
    field :retirement_other, :map
    field :hex_updated_at, :utc_datetime
    field :api_url, :string
    field :version, :string

    timestamps()
  end

  @doc false
  def changeset(release \\ %__MODULE__{}, attrs) do
    release
    |> cast(attrs, [
      :hex_etag,
      :checksum,
      :package_id,
      :docs_html_url,
      :downloads,
      :has_docs,
      :html_url,
      :hex_inserted_at,
      :app,
      :build_tools,
      :elixir_version,
      :meta_other,
      :api_package_url,
      :publisher_other,
      :hex_updated_at,
      :api_url,
      :version,
      :retirement_other
    ])
    |> cast_embed(:config_snippets)
    |> cast_embed(:publisher)
    |> cast_embed(:requirements)
    |> cast_embed(:retirement)
    |> validate_required([:package_id, :version])
    |> unique_constraint([:package_id, :version])
    |> foreign_key_constraint(:package_id)
  end
end
