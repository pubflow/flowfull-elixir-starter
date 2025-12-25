# Quick Reference

## Commands

```bash
# Setup
mix deps.get
mix assets.setup

# Database
mix ecto.gen.migration migration_name
mix ecto.migrate
mix ecto.rollback

# Development
mix phx.server
iex -S mix phx.server  # With IEx shell

# Testing
mix test
```

## Auth

- **Header**: `X-Session-Id` (normalized to `x-session-id` by Plug)
- **Cookie**: `session_id` (alternative to header)
- **Bridge header**: `X-Bridge-Secret`
- **Claims** are in `conn.assigns[:auth_claims]`

## Pipelines

- `:browser` - HTML pages, CSRF protection
- `:api` - JSON, optional auth (`OptionalMiddleware`)
- `:api_auth` - JSON, required auth (`Middleware`)

## Middleware Patterns

```elixir
# Required auth
scope "/api/secure", MyAppWeb do
  pipe_through :api_auth
  get "/resource", MyController, :resource
end

# Optional auth
scope "/api", MyAppWeb do
  pipe_through :api
  get "/content", MyController, :content
end

# Check user_type
defp admin?(%{"user_type" => type}) when type in ["admin", "superadmin"], do: true
defp admin?(_), do: false
```

## Database (Ecto)

```elixir
alias MyApp.Repo
alias MyApp.Models.User

# Query
Repo.all(User)
Repo.get(User, id)
from(u in User, where: u.active == true) |> Repo.all()

# Insert
%User{id: "id", email: "test@example.com"} |> Repo.insert()

# Update
user |> Ecto.Changeset.change(%{name: "New"}) |> Repo.update()

# Delete
Repo.delete(user)
```

## WebSocket Channels

```elixir
# Join
def join("topic:subtopic", _payload, socket) do
  if socket.assigns[:auth_claims] do
    {:ok, socket}
  else
    {:error, %{reason: "unauthorized"}}
  end
end

# Handle incoming
def handle_in("event", payload, socket) do
  broadcast!(socket, "event", payload)
  {:noreply, socket}
end
```

## Useful Routes

- `/` - Home page
- `/api/health` - Health check
- `/api/public` - Public API
- `/api/content` - Optional auth
- `/api/secure/me` - Current user
- `/api/secure/profile` - User profile
- `/api/secure/admin/users` - List users (admin)
- `/ws` - WebSocket test page

## Environment Variables

Required:
- `FLOWLESS_API_URL`
- `BRIDGE_VALIDATION_SECRET`

Optional:
- `DATABASE_URL`
- `DEV_ALLOW_BRIDGE_STUB=1`
- `PORT=4000`
- `POOL_SIZE=10`

## Error Responses

- `401` - Unauthorized (no/invalid session)
- `403` - Forbidden (wrong user_type)
- `404` - Not found
- `503` - Service unavailable (DB not configured)

## Tips

- Use `IO.inspect/2` for debugging
- Phoenix auto-reloads code in dev
- Header names are lowercase (`x-session-id`)
- Repo only starts if `DATABASE_URL` set
- Wrap Repo calls in try/rescue for graceful errors
