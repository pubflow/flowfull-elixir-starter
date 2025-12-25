defmodule FlowfullElixirStarterWeb.UserSocket do
  use Phoenix.Socket
  require Logger

  channel "public:*", FlowfullElixirStarterWeb.PublicChannel
  channel "secure:*", FlowfullElixirStarterWeb.SecureChannel

  def connect(params, socket, _connect_info) do
    case Map.get(params, "session_id") do
      nil ->
        Logger.info("WebSocket connection without session_id")
        {:ok, socket}

      session_id ->
        Logger.info("WebSocket connection with session_id: #{String.slice(session_id, 0..7)}...")

        case FlowfullElixirStarter.Auth.BridgeValidator.validate_session_id(session_id) do
          {:ok, claims} ->
            Logger.info("Session validated for WebSocket: user_id=#{claims["user_id"]}")
            {:ok, Phoenix.Socket.assign(socket, :auth_claims, claims)}

          error ->
            Logger.warning("Session validation failed for WebSocket: #{inspect(error)}")
            {:ok, socket}
        end
    end
  end

  def id(_socket), do: nil
end
