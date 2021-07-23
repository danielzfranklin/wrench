defmodule Wrench.Hex.Api.RequesterTest do
  use ExUnit.Case, async: true
  alias Wrench.Hex.Api.Requester

  @epoch DateTime.from_unix!(0)

  test "making a request returns reply" do
    {:ok, pid} =
      Requester.start_link(
        [
          make_request: fn _req ->
            {:ok,
             {:dummy_reply,
              %{
                remaining: 1,
                reset_time: @epoch
              }}}
          end
        ],
        nil
      )

    {:ok, :dummy_reply} = Requester.request(%{method: :get, path: "foo"}, pid)
  end

  test "request without quota goes through if reset time in past" do
    {:ok, pid} =
      Requester.start_link(
        [
          make_request: fn _req ->
            {:ok,
             {:dummy_reply,
              %{
                remaining: 0,
                reset_time: @epoch
              }}}
          end
        ],
        nil
      )

    {:ok, _} = Requester.request(%{method: :get, path: "foo"}, pid)
    {:ok, _} = Requester.request(%{method: :get, path: "bar"}, pid)
  end

  test "making a request without quota blocks" do
    {:ok, pid} =
      Requester.start_link(
        [
          make_request: fn _req ->
            {:ok,
             {:dummy_reply,
              %{
                remaining: 0,
                reset_time: DateTime.utc_now() |> DateTime.add(10, :second)
              }}}
          end
        ],
        nil
      )

    {:ok, _} = Requester.request(%{method: :get, path: "foo"}, pid, 500)
    {:timeout, _} = catch_exit(Requester.request(%{method: :get, path: "bar"}, pid, 500))
  end

  test "quota correctly resets" do
    {:ok, pid} =
      Requester.start_link(
        [
          make_request: fn _req ->
            {:ok,
             {:dummy_reply,
              %{
                remaining: 0,
                reset_time: DateTime.utc_now() |> DateTime.add(50, :millisecond)
              }}}
          end
        ],
        nil
      )

    {:ok, _} = Requester.request(%{method: :get, path: "foo"}, pid, 500)
    {:ok, _} = Requester.request(%{method: :get, path: "bar"}, pid, 500)
  end

  test "one request is issued per request" do
    caller = self()

    {:ok, pid} =
      Requester.start_link(
        [
          make_request: fn req ->
            send(caller, {:requesting, req})

            {:ok,
             {:dummy_reply,
              %{
                remaining: 0,
                reset_time: DateTime.utc_now() |> DateTime.add(1, :millisecond)
              }}}
          end
        ],
        nil
      )

    req_foo = %{method: :get, path: "foo"}
    req_bar = %{method: :get, path: "bar"}
    req_baq = %{method: :get, path: "baq"}

    {:ok, _} = Requester.request(req_foo, pid, 500)
    {:ok, _} = Requester.request(req_bar, pid, 500)
    {:ok, _} = Requester.request(req_baq, pid, 500)

    {:messages, messages} = Process.info(caller, :messages)
    assert length(messages) == 3

    assert_received {:requesting, ^req_foo}
    assert_received {:requesting, ^req_bar}
    assert_received {:requesting, ^req_baq}

    {:messages, messages} = Process.info(caller, :messages)
    assert length(messages) == 0
  end
end
