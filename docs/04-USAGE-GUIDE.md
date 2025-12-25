# Usage Guide

## Start the Server

```bash
# Install dependencies
mix deps.get

# Compile assets (first time only)
mix assets.setup

# Start development server
mix phx.server

# Start with IEx shell for interactive debugging
iex -S mix phx.server
```

Access at: `http://localhost:4000`

## Example Routes

### Public Routes (No Auth)
- `GET /api/health` - Health check
- `GET /api/public` - Public content
- `GET /api/content` - Mixed content (optional auth)

### Authenticated Routes
- `GET /api/secure/me` - Current user info
- `GET /api/secure/profile` - User profile
- `GET /api/secure/protected` - Protected resource

### Admin-Only Routes
- `GET /api/secure/admin/dashboard` - Admin dashboard
- `GET /api/secure/admin/users` - List all users (DB query)
- `GET /api/secure/admin/users/:id` - Get user by ID (DB query)
- `GET /api/secure/users` - List all users (alias)
- `GET /api/secure/users/:id` - Get user by ID (alias)

### WebSocket Test Page
- `GET /ws` - Interactive WebSocket test client

## Adding Routes

### 1. Public Route (No Auth)

```elixir
# In lib/flowfull_elixir_starter_web/router.ex
scope "/api", FlowfullElixirStarterWeb do
  pipe_through :api
  
  get "/hello", MyController, :hello
end

# In lib/flowfull_elixir_starter_web/controllers/my_controller.ex
defmodule FlowfullElixirStarterWeb.MyController do
  use FlowfullElixirStarterWeb, :controller
  
  def hello(conn, _params) do
    json(conn, %{message: "Hello, world!"})
  end
end
```

### 2. Optional Auth Route

```elixir
# Uses :api pipeline with OptionalMiddleware
scope "/api", FlowfullElixirStarterWeb do
  pipe_through :api
  
  get "/content", MyController, :content
end

# In controller
def content(conn, _params) do
  claims = conn.assigns[:auth_claims]
  
  if claims do
    json(conn, %{message: "Hello, #{claims["name"]}", personalized: true})
  else
    json(conn, %{message: "Hello, guest", personalized: false})
  end
end
```

### 3. Required Auth Route

```elixir
# Uses :api_auth pipeline with Middleware
scope "/api/secure", FlowfullElixirStarterWeb do
  pipe_through :api_auth
  
  get "/dashboard", MyController, :dashboard
end

# In controller
def dashboard(conn, _params) do
  claims = conn.assigns[:auth_claims]
  user_id = claims["user_id"]
  
  json(conn, %{user_id: user_id, data: "secured content"})
end
```

### 4. Admin-Only Route

```elixir
scope "/api/secure", FlowfullElixirStarterWeb do
  pipe_through :api_auth
  
  get "/admin/reports", MyController, :admin_reports
end

# In controller
def admin_reports(conn, _params) do
  claims = conn.assigns[:auth_claims] || %{}
  
  if admin?(claims) do
    json(conn, %{reports: []})
  else
    conn
    |> put_status(403)
    |> json(%{error: "forbidden"})
  end
end

defp admin?(%{"user_type" => type}) when type in ["admin", "superadmin"], do: true
defp admin?(_), do: false
```

## Working with Models

### 1. Create a Model

```elixir
# lib/flowfull_elixir_starter/models/post.ex
defmodule FlowfullElixirStarter.Models.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "posts" do
    field :title, :string
    field :content, :string
    field :author_id, :string
    field :published, :boolean, default: false
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:id, :title, :content, :author_id, :published])
    |> validate_required([:id, :title, :content, :author_id])
    |> validate_length(:title, min: 3, max: 200)
  end
end
```

### 2. Create Migration

```bash
mix ecto.gen.migration create_posts
```

Edit the migration file in `priv/repo/migrations/`:

```elixir
defmodule FlowfullElixirStarter.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :string, primary_key: true
      add :title, :string, null: false
      add :content, :text
      add :author_id, :string, null: false
      add :published, :boolean, default: false
    end

    create index(:posts, [:author_id])
  end
end
```

Run migration:

```bash
mix ecto.migrate
```

### 3. Query the Model

```elixir
alias FlowfullElixirStarter.Repo
alias FlowfullElixirStarter.Models.Post
import Ecto.Query

# Get all posts
posts = Repo.all(Post)

# Get by ID
post = Repo.get(Post, "post-id")

# Query with filter
published_posts = 
  from(p in Post, where: p.published == true)
  |> Repo.all()

# Insert
%Post{
  id: "new-post-id",
  title: "My Post",
  content: "Content here",
  author_id: "author-id"
}
|> Repo.insert()

# Update
post
|> Ecto.Changeset.change(%{published: true})
|> Repo.update()

# Delete
Repo.delete(post)
```

### 4. Handle Repo Errors

```elixir
def list_posts(conn, _params) do
  try do
    posts = Repo.all(Post)
    json(conn, posts)
  rescue
    RuntimeError ->
      conn
      |> put_status(503)
      |> json(%{error: "database not configured"})
  end
end
```

## Working with WebSocket Channels

### 1. Create a Channel

```elixir
# lib/flowfull_elixir_starter_web/channels/chat_channel.ex
defmodule FlowfullElixirStarterWeb.ChatChannel do
  use FlowfullElixirStarterWeb, :channel

  @impl true
  def join("chat:lobby", _payload, socket) do
    # Public channel - no auth required
    {:ok, socket}
  end

  def join("chat:private", _payload, socket) do
    # Secure channel - auth required
    if socket.assigns[:auth_claims] do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast!(socket, "new_msg", %{body: body})
    {:noreply, socket}
  end
end
```

### 2. Register Channel

```elixir
# In lib/flowfull_elixir_starter_web/user_socket.ex
defmodule FlowfullElixirStarterWeb.UserSocket do
  use Phoenix.Socket
  
  channel "public:*", FlowfullElixirStarterWeb.PublicChannel
  channel "secure:*", FlowfullElixirStarterWeb.SecureChannel
  channel "chat:*", FlowfullElixirStarterWeb.ChatChannel  # Add this
  
  # ... rest of code
end
```

### 3. Test WebSocket

Visit `http://localhost:4000/ws` for interactive WebSocket testing.

## Testing with cURL

### Public Route
```bash
curl http://localhost:4000/api/public
```

### Authenticated Route
```bash
curl http://localhost:4000/api/secure/profile \
  -H "X-Session-Id: your-session-id-here"
```

### Admin Route
```bash
curl http://localhost:4000/api/secure/admin/users \
  -H "X-Session-Id: admin-session-id-here"
```

## Tips

- Use `IO.inspect/2` for debugging (output shows in terminal)
- Use `iex -S mix phx.server` for interactive debugging with IEx
- Phoenix live reloads code automatically in development
- Check logs for session validation details
- Use `/ws` page to test WebSocket functionality interactively
- Wrap all Repo calls in try/rescue when DB is optional
