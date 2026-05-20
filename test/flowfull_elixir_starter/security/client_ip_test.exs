defmodule FlowfullElixirStarter.Security.ClientIPTest do
  use ExUnit.Case, async: true
  import Plug.Conn
  import Plug.Test

  alias FlowfullElixirStarter.Security.ClientIP

  test "uses the first x-forwarded-for client IP" do
    conn =
      conn(:get, "/")
      |> put_req_header("x-forwarded-for", "203.0.113.7, 172.18.0.2")

    assert ClientIP.from_conn(conn) == "203.0.113.7"
  end

  test "normalizes RFC 7239 forwarded header" do
    conn =
      conn(:get, "/")
      |> put_req_header("forwarded", ~s(for="[2001:db8::1]:443";proto=https))

    assert ClientIP.from_conn(conn) == "2001:db8::1"
  end
end
