defmodule FlowfullElixirStarter.Auth.Middleware do
  import Plug.Conn
  alias FlowfullElixirStarter.Auth.ValidationMode
  alias FlowfullElixirStarter.Auth.BridgeValidator

  def init(opts), do: opts

  def call(conn, _opts) do
    mode = ValidationMode.current()

    case mode do
      :disabled ->
        conn

      _ ->
        case extract_session_id(conn) do
          nil ->
            unauthorized(conn)

          session_id ->
            case BridgeValidator.validate_session_id(session_id) do
              {:ok, claims} -> assign(conn, :auth_claims, claims)
              _ -> unauthorized(conn)
            end
        end
    end
  end

  defp extract_session_id(conn) do
    # Plug normalizes headers to lowercase
    header_name = System.get_env("SESSION_HEADER_NAME") || "x-session-id"
    cookie_name = System.get_env("SESSION_COOKIE_NAME") || "session_id"

    case get_req_header(conn, header_name) do
      [sid | _] when byte_size(sid) > 0 ->
        require Logger
        Logger.debug("Session extracted from header: #{String.slice(sid, 0..7)}...")
        sid

      _ ->
        case conn.req_cookies[cookie_name] do
          sid when is_binary(sid) and byte_size(sid) > 0 ->
            require Logger
            Logger.debug("Session extracted from cookie: #{String.slice(sid, 0..7)}...")
            sid

          _ ->
            require Logger

            Logger.warning(
              "No session_id found in header (#{header_name}) or cookie (#{cookie_name})"
            )

            nil
        end
    end
  end

  defp unauthorized(conn) do
    conn
    |> send_resp(401, Jason.encode!(%{error: "unauthorized"}))
    |> halt()
  end
end
