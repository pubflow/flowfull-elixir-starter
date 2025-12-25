defmodule FlowfullElixirStarterWeb.SampleController do
  use FlowfullElixirStarterWeb, :controller
  alias FlowfullElixirStarter.Repo
  alias FlowfullElixirStarter.Models.User

  # Public, no auth
  def public(conn, _params) do
    json(conn, %{
      message: "This is a public route",
      timestamp: DateTime.utc_now(),
      authenticated: false
    })
  end

  # Optional-auth style content
  def content(conn, _params) do
    claims = conn.assigns[:auth_claims]

    if claims do
      json(conn, %{
        message: "Welcome back, #{claims["name"] || claims["email"] || claims["user_id"]}!",
        premium_content: true,
        user_id: claims["user_id"],
        authenticated: true
      })
    else
      json(conn, %{
        message: "Welcome, guest!",
        premium_content: false,
        authenticated: false
      })
    end
  end

  # Auth required via middleware
  def profile(conn, _params) do
    claims = conn.assigns[:auth_claims] || %{}

    json(conn, %{
      user_id: claims["user_id"],
      email: claims["email"],
      name: claims["name"],
      user_type: claims["user_type"],
      organization_id: claims["organization_id"],
      permissions: claims["permissions"]
    })
  end

  def protected(conn, _params) do
    claims = conn.assigns[:auth_claims] || %{}

    json(conn, %{
      message: "Hello #{claims["name"] || claims["email"] || claims["user_id"]}!",
      user_id: claims["user_id"],
      timestamp: DateTime.utc_now(),
      authenticated: true
    })
  end

  def admin_dashboard(conn, _params) do
    claims = conn.assigns[:auth_claims] || %{}

    if admin?(claims) do
      json(conn, %{
        message: "Admin dashboard",
        user_id: claims["user_id"],
        user_type: claims["user_type"],
        timestamp: DateTime.utc_now()
      })
    else
      forbid(conn)
    end
  end

  def admin_users(conn, _params) do
    claims = conn.assigns[:auth_claims] || %{}

    if admin?(claims) do
      try do
        users =
          Repo.all(User)
          |> Enum.map(fn user ->
            %{
              id: user.id,
              email: user.email,
              name: user.name,
              last_name: user.last_name,
              user_type: user.user_type
            }
          end)

        json(conn, users)
      rescue
        RuntimeError ->
          conn
          |> put_status(503)
          |> json(%{
            error: "database not configured",
            message: "Set DATABASE_URL environment variable"
          })
      end
    else
      forbid(conn)
    end
  end

  def admin_user(conn, %{"id" => id}) do
    claims = conn.assigns[:auth_claims] || %{}

    if admin?(claims) do
      try do
        case Repo.get(User, id) do
          nil ->
            conn |> put_status(404) |> json(%{error: "user not found"})

          user ->
            json(conn, %{
              id: user.id,
              email: user.email,
              name: user.name,
              last_name: user.last_name,
              user_type: user.user_type
            })
        end
      rescue
        RuntimeError ->
          conn
          |> put_status(503)
          |> json(%{
            error: "database not configured",
            message: "Set DATABASE_URL environment variable"
          })
      end
    else
      forbid(conn)
    end
  end

  defp admin?(%{"user_type" => type}) when type in ["admin", "superadmin"], do: true
  defp admin?(_), do: false

  defp forbid(conn) do
    conn |> put_status(403) |> json(%{error: "forbidden"})
  end
end
