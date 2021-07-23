defmodule Wrench.Hex.Importer do
  alias Wrench.Hex.Api
  alias Wrench.Packages.Package
  alias Wrench.Packages.Release
  alias Wrench.Repo
  import Ecto.Query

  @spec import_updated_since(DateTime.t()) :: nil
  def import_updated_since(since \\ latest_update()) do
    new = Api.full_packages_updated_since(since, &get_release_etag/2)

    for {pkg, releases} <- new do
      Repo.transaction(fn ->
        %Package{id: pkg_id} =
          pkg_to_changeset(pkg)
          |> Repo.insert!(on_conflict: :replace_all, conflict_target: [:name])

        for rel <- releases do
          release_to_changeset(rel, pkg_id)
          |> Repo.insert!(on_conflict: :replace_all, conflict_target: [:package_id, :version])
        end
      end)
    end

    nil
  end

  defp get_release_etag(pkg_name, rel_version),
    do:
      Release
      |> join(:inner, [rel], pkg in Package, on: rel.package_id == pkg.id)
      |> where([rel, pkg], pkg.name == ^pkg_name and rel.version == ^rel_version)
      |> select([rel, pkg], rel.hex_etag)
      |> Repo.one()

  def latest_update,
    do:
      Package
      |> order_by(desc: :hex_updated_at)
      |> limit(1)
      |> select([pkg], pkg.hex_updated_at)
      |> Repo.one()

  @spec pkg_to_changeset(map) :: Ecto.Changeset.t()
  defp pkg_to_changeset(pkg) do
    meta_all = pkg["meta"]

    description = meta_all["description"]
    licenses = Map.get(meta_all, "licenses", [])

    links =
      Map.get(meta_all, "links", %{})
      |> Map.to_list()
      |> Enum.map(fn {title, value} -> %{title: title, value: value} end)

    meta_other = Map.drop(meta_all || %{}, ["description", "licenses", "links"])

    downloads = pkg["downloads"]

    Package.changeset(%{
      config_snippets: get_config_snippets(pkg),
      meta_other: meta_other,
      docs_html_url: pkg["docs_html_url"],
      description: description,
      downloads_all: downloads["all"],
      downloads_day: downloads["day"],
      downloads_recent: downloads["recent"],
      downloads_week: downloads["week"],
      html_url: pkg["html_url"],
      hex_inserted_at: pkg["inserted_at"],
      latest_stable_version: pkg["latest_stable_version"],
      latest_version: pkg["latest_version"],
      licenses: licenses,
      links: links,
      name: pkg["name"],
      repository: pkg["repository"],
      hex_updated_at: pkg["updated_at"],
      api_url: pkg["url"]
    })
  end

  @spec release_to_changeset({binary, map}, integer) :: Ecto.Changeset.t()
  defp release_to_changeset({etag, rel}, package_id) do
    meta_all = rel["meta"]
    app = meta_all["app"]
    build_tools = meta_all["build_tools"]
    elixir_version = meta_all["elixir"]
    meta_other = Map.drop(meta_all || %{}, ["app", "build_tools", "elixir_version"])

    requirements =
      Map.get(rel, "requirements", %{})
      |> Map.values()

    publisher = rel["publisher"]
    publisher_other = Map.drop(publisher || %{}, ["email", "url", "username"])

    retirement = rel["retirement"]
    retirement_other = Map.drop(retirement || %{}, ["reason", "message"])

    Release.changeset(%{
      hex_etag: etag,
      checksum: rel["checksum"],
      package_id: package_id,
      config_snippets: get_config_snippets(rel),
      docs_html_url: rel["docs_html_url"],
      downloads: rel["downloads"],
      has_docs: rel["has_docs"],
      html_url: rel["html_url"],
      hex_inserted_at: rel["inserted_at"],
      app: app,
      build_tools: build_tools,
      elixir_version: elixir_version,
      meta_other: meta_other,
      api_package_url: rel["package_url"],
      publisher: publisher,
      publisher_other: publisher_other,
      requirements: requirements,
      retirement: retirement,
      retirement_other: retirement_other,
      hex_updated_at: rel["updated_at"],
      api_url: rel["url"],
      version: rel["version"]
    })
  end

  defp get_config_snippets(map),
    do:
      Map.get(map, "configs", %{})
      |> Map.to_list()
      |> Enum.map(fn {tool, value} ->
        %{tool: tool, value: value}
      end)
end
