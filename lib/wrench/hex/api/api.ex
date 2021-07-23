defmodule Wrench.Hex.Api do
  require Logger
  alias Wrench.Hex.Api.Requester

  @doc """
    - get_release_etag: (pkg_name, release_version) -> binary
    - returns: Stream of {pkg_map, [{etag, release_map}, ...]}
  """
  def full_packages_updated_since(since, get_release_etag) do
    packages_updated_since(since)
    |> Stream.map(fn pkg ->
      name = Map.fetch!(pkg, "name")

      releases =
        Map.fetch!(pkg, "releases")
        |> Enum.map(fn %{"version" => version} ->
          package_release(name, version, get_release_etag.(name, version))
        end)

      {pkg, releases}
    end)
  end

  def packages_updated_since(since) do
    Stream.resource(
      fn -> 0 end,
      fn page ->
        pkgs =
          packages_page_update_order(page)
          |> Enum.filter(fn pkg ->
            if is_nil(since) do
              true
            else
              {:ok, updated_at, 0} = DateTime.from_iso8601(pkg["updated_at"])
              DateTime.compare(updated_at, since) != :lt
            end
          end)

        if Enum.count(pkgs) == 0 do
          {:halt, nil}
        else
          {pkgs, page + 1}
        end
      end,
      fn _ -> nil end
    )
  end

  defp packages_page_update_order(page) do
    {:ok, %Finch.Response{body: body}} =
      Requester.request(%{
        method: :get,
        path: "packages",
        params: [{"sort", "updated_at"}, {"page", page}]
      })

    Jason.decode!(body)
  end

  @spec package_release(String.t(), String.t(), String.t()) :: {binary, map()}
  def package_release(name, version, etag \\ nil) do
    {:ok, %Finch.Response{body: body, headers: headers}} =
      Requester.request(%{
        method: :get,
        path: "packages/#{name}/releases/#{version}",
        etag: etag
      })

    {_, etag} = List.keyfind(headers, "etag", 0)

    {etag, Jason.decode!(body)}
  end
end
