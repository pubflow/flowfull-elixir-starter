defmodule FlowfullElixirStarter.Auth.OptionalMiddleware do
  @moduledoc """
  Optional auth middleware: assigns :auth_claims if a valid session_id is present;
  otherwise passes through without halting.
  """

  import Plug.Conn
  alias FlowfullElixirStarter.Auth.BridgeValidator
  alias FlowfullElixirStarter.Security.ClientIP

  def init(opts), do: opts

  def call(conn, _opts) do
    case extract_session_id(conn) do
      nil ->
        conn

      session_id ->
        case BridgeValidator.validate_session_id(session_id, validation_options(conn)) do
          {:ok, claims} -> assign(conn, :auth_claims, claims)
          _ -> conn
        end
    end
  end

  defp extract_session_id(conn) do
    # Plug normalizes headers to lowercase
    header_name = System.get_env("SESSION_HEADER_NAME") || "x-session-id"
    cookie_name = System.get_env("SESSION_COOKIE_NAME") || "session_id"

    case get_req_header(conn, header_name) do
      [sid | _] when byte_size(sid) > 0 ->
        sid

      _ ->
        case conn.req_cookies[cookie_name] do
          sid when is_binary(sid) and byte_size(sid) > 0 -> sid
          _ -> nil
        end
    end
  end

  defp validation_options(conn) do
    %{
      ip: ClientIP.from_conn(conn),
      user_agent: conn |> get_req_header("user-agent") |> List.first()
    }
  end
end
