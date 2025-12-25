defmodule FlowfullElixirStarterWeb.SecureChannel do
  use Phoenix.Channel
  require Logger

  @impl true
  def join("secure:" <> topic, _params, socket) do
    case socket.assigns[:auth_claims] do
      nil ->
        Logger.warning("Unauthorized attempt to join secure:#{topic}")
        {:error, %{reason: "unauthorized", message: "Valid session_id required"}}

      claims ->
        Logger.info("User #{claims["user_id"]} joined secure:#{topic}")
        {:ok, socket}
    end
  end

  @impl true
  def handle_in("ping", payload, socket) do
    Logger.debug("Received ping in secure channel: #{inspect(payload)}")
    push(socket, "pong", payload)
    {:noreply, socket}
  end
end
