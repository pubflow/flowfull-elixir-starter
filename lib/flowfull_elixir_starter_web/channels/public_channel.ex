defmodule FlowfullElixirStarterWeb.PublicChannel do
  use Phoenix.Channel

  def join("public:" <> _topic, _params, socket) do
    {:ok, socket}
  end

  def handle_in("ping", payload, socket) do
    push(socket, "pong", payload)
    {:noreply, socket}
  end
end
