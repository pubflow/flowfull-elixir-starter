defmodule FlowfullElixirStarterWeb.TaskController do
  use FlowfullElixirStarterWeb, :controller

  def index(conn, _params) do
    tasks = FlowfullElixirStarter.Models.Task.list()
    json(conn, tasks)
  end

  def create(conn, params) do
    case FlowfullElixirStarter.Models.Task.create(params) do
      {:ok, task} ->
        conn
        |> put_status(201)
        |> json(task)

      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{error: inspect(reason)})
    end
  end
end
