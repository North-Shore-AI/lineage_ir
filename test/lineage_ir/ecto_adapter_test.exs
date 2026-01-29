defmodule LineageIR.TestSupport.StubRepo do
  @moduledoc false

  def insert_all(source, entries, opts) do
    send(self(), {:insert_all, source, entries, opts})
    {length(entries), nil}
  end
end

defmodule LineageIR.EctoAdapterTest do
  use ExUnit.Case, async: true

  alias LineageIR.Event
  alias LineageIR.Sink.Adapters.Ecto, as: EctoAdapter
  alias LineageIR.TestSupport.StubRepo

  defp now do
    DateTime.utc_now() |> DateTime.truncate(:microsecond)
  end

  test "write_event uses idempotent conflict handling" do
    event = %Event{
      id: Ecto.UUID.generate(),
      type: "log",
      trace_id: Ecto.UUID.generate(),
      occurred_at: now(),
      source: "command",
      source_ref: "session_1",
      payload: %{"message" => "hello"}
    }

    assert :ok = EctoAdapter.write_event(event, repo: StubRepo)

    assert_received {:insert_all, "events", [_entry], opts}
    assert opts[:prefix] == "lineage"
    assert opts[:conflict_target] == [:id]
    assert opts[:on_conflict] == :nothing
  end
end
