defmodule Wrench.Hex.Api.Requester do
  use GenServer
  require Logger

  @config Application.get_env(:wrench, __MODULE__)
  @api_key @config[:api_key]
  @ua "Wrench/#{Application.spec(:wrench, :vsn)} (contact #{Application.get_env(:wrench, :operator_contact)})"
  @endpoint "https://hex.pm/api"
  @epoch DateTime.from_unix!(0)

  @doc """
  ## Opts
  - make_request: Optional, mostly for testing.
      Should have same behavior as private fun `__MODULE__.make_request/1`
  """
  def start_link(opts, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def request(request, server \\ __MODULE__, timeout \\ 5000) do
    GenServer.call(server, {:request, request}, timeout)
  end

  @impl true
  def init(opts) do
    {:ok,
     %{
       make_request: Keyword.get(opts, :make_request, &make_request/1),
       quota: %{
         remaining: 1,
         reset_time: @epoch
       },
       todo: []
     }}
  end

  @impl true
  def handle_call({:request, request}, from, state) do
    handle_request(request, from, state)
  end

  @impl true
  def handle_info(:handle_todo, %{todo: todo} = state) when length(todo) == 0,
    do: {:noreply, state}

  @impl true
  def handle_info(:handle_todo, %{todo: todo} = state) when length(todo) > 0 do
    {{from, request}, todo} = List.pop_at(state.todo, 0)
    state = %{state | todo: todo}

    with {:reply, reply, state} <- handle_request(request, from, state) do
      send(self(), :handle_todo)
      GenServer.reply(from, reply)
      {:noreply, state}
    end
  end

  defp handle_request(request, from, state) do
    quota =
      if state.quota.remaining <= 0 && past_reset(state) do
        # Give us one request to find the new limits
        %{state.quota | remaining: 1, reset_time: @epoch}
      else
        state.quota
      end

    if quota.remaining > 0 do
      with {:ok, {reply, new_quota}} <- state.make_request.(request) do
        {:reply, {:ok, reply}, %{state | quota: new_quota}}
      else
        {:error, err} ->
          # In the case of a transport error don't remove quota
          {:reply, {:error, err}, state}
      end
    else
      until_reset = DateTime.diff(quota.reset_time, DateTime.utc_now(), :second)
      Logger.info("Waiting #{until_reset} seconds until quota reset")
      # put todo back
      state = %{state | todo: state.todo ++ [{from, request}]}
      Process.send_after(self(), :handle_todo, until_reset)
      {:noreply, state}
    end
  end

  defp past_reset(state), do: DateTime.compare(state.quota.reset_time, DateTime.utc_now()) != :gt

  defp make_request(%{method: method, path: path} = request) do
    Logger.info("Requesting #{inspect(request)}")

    # Optional params
    params = Map.get(request, :params)
    body = Map.get(request, :body)
    etag = Map.get(request, :etag)

    headers = [{"Authorization", @api_key}, {"User-Agent", @ua}]

    headers =
      if is_nil(etag) do
        headers
      else
        [{"ETag", etag} | headers]
      end

    url =
      if is_nil(params) do
        "#{@endpoint}/#{path}"
      else
        "#{@endpoint}/#{path}?#{URI.encode_query(params, :rfc3986)}"
      end

    reply =
      Finch.build(
        method,
        url,
        headers,
        body
      )
      |> Finch.request(Wrench.Finch)

    with {:ok, %Finch.Response{headers: headers} = reply} <- reply do
      headers = Map.new(headers)
      {remaining, ""} = headers["x-ratelimit-remaining"] |> Integer.parse()
      {reset, ""} = headers["x-ratelimit-reset"] |> Integer.parse()
      {:ok, reset} = DateTime.from_unix(reset)

      {:ok, {reply, %{remaining: remaining, reset_time: reset}}}
    end
  end
end
