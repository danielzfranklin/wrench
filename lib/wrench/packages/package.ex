defmodule Wrench.Packages.Package do
  use Ecto.Schema
  import Ecto.Changeset
  alias Wrench.Packages.ConfigSnippet
  alias Wrench.Packages.Link

  schema "packages" do
    embeds_many :config_snippets, ConfigSnippet, on_replace: :delete
    field :meta_other, :map
    field :docs_html_url, :string
    field :description, :string
    field :downloads_all, :integer
    field :downloads_day, :integer
    field :downloads_recent, :integer
    field :downloads_week, :integer
    field :html_url, :string
    field :hex_inserted_at, :utc_datetime
    field :latest_stable_version, :string
    field :latest_version, :string
    field :licenses, {:array, :string}
    embeds_many :links, Link, on_replace: :delete
    field :name, :string
    field :repository, :string
    field :hex_updated_at, :utc_datetime
    field :api_url, :string

    timestamps()
  end

  @doc false
  def changeset(package \\ %__MODULE__{}, attrs) do
    package
    |> cast(attrs, [
      :meta_other,
      :docs_html_url,
      :description,
      :downloads_all,
      :downloads_day,
      :downloads_recent,
      :downloads_week,
      :html_url,
      :hex_inserted_at,
      :latest_stable_version,
      :latest_version,
      :licenses,
      :name,
      :repository,
      :hex_updated_at,
      :api_url
    ])
    |> cast_embed(:config_snippets)
    |> cast_embed(:links)
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
