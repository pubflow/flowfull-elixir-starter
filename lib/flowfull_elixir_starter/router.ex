defmodule FlowfullElixirStarter.Router do
  use Plug.Router

  plug :match
  plug FlowfullElixirStarter.Auth.Middleware
  plug :dispatch

  get "/health" do
    send_resp(conn, 200, Jason.encode!(%{status: "ok"}))
  end

  get "/api/tasks" do
    tasks = FlowfullElixirStarter.Models.Task.list()
    send_resp(conn, 200, Jason.encode!(tasks))
  end

  post "/api/tasks" do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    params = Jason.decode!(body)

    case FlowfullElixirStarter.Models.Task.create(params) do
      {:ok, task} -> send_resp(conn, 201, Jason.encode!(task))
      {:error, reason} -> send_resp(conn, 400, Jason.encode!(%{error: inspect(reason)}))
    end
  end

  match _ do
    send_resp(conn, 404, Jason.encode!(%{error: "not_found"}))
  end
end
