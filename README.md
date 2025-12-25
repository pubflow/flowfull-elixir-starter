# Flowfull Elixir Starter

Production-ready Elixir/Phoenix backend template with Flowless integration, featuring WebSocket support and modern async patterns.

## 🚀 Features

### Core Capabilities

1. **Bridge Validation** - Distributed session validation with Flowless
2. **Auth Middleware** - Pipeline-based route protection (required/optional)
3. **WebSocket Channels** - Real-time communication with auth integration
4. **Multi-Database** - Support for PostgreSQL (including CockroachDB), MySQL, and SQLite
5. **Environment Config** - .env file loading with Dotenvy
6. **Ecto ORM** - Database operations with optional Repo (starts only if DATABASE_URL set)
7. **Interactive Testing** - Built-in WebSocket test page at `/ws`

### Technology Stack

- **Elixir 1.14+** - Functional programming with OTP
- **Phoenix 1.8+** - Modern web framework
- **Bandit** - High-performance HTTP/2 server
- **Ecto 3.x** - Database wrapper and query DSL
- **Phoenix Channels** - WebSocket communication
- **Dotenvy** - Environment configuration
- **Req** - HTTP client for bridge validation

## 📦 Quick Start

### 1. Installation

```bash
# Clone the repository
git clone <repository-url>
cd flowfull_elixir_starter

# Install dependencies
mix deps.get

# Compile assets (first time only)
mix assets.setup
```

### 2. Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env
```

**Minimum required configuration:**

```env
FLOWLESS_API_URL=https://api.pubflow.com
BRIDGE_VALIDATION_SECRET=your-shared-secret-min-32-chars
```

**Optional configuration (for database):**

```env
DATABASE_URL=postgresql://user:pass@localhost:5432/flowfull_dev
```

### 3. Database Setup (Optional)

If using a database:

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate
```

### 4. Run Development Server

```bash
# Start server with hot reload
mix phx.server

# Or start with IEx shell for debugging
iex -S mix phx.server

# Server will be available at:
# - Home: http://localhost:4000
# - Health: http://localhost:4000/api/health
# - WebSocket Test: http://localhost:4000/ws
```

## 🌐 API Endpoints

### Public Routes (No Authentication)

- `GET /` - Home page
- `GET /api/health` - Health check
- `GET /api/public` - Public content
- `GET /api/content` - Mixed content (optional auth)

### Protected Routes (Authentication Required)

- `GET /api/secure/me` - Current user information
- `GET /api/secure/profile` - User profile
- `GET /api/secure/protected` - Protected resource

### Admin Routes (Admin User Type Required)

- `GET /api/secure/admin/dashboard` - Admin dashboard
- `GET /api/secure/admin/users` - List all users (DB query)
- `GET /api/secure/admin/users/:id` - Get user by ID (DB query)
- `GET /api/secure/users` - List all users (alias)
- `GET /api/secure/users/:id` - Get user by ID (alias)

## 🔌 WebSocket Support

### Testing WebSocket

Visit `http://localhost:4000/ws` for an interactive WebSocket test page.

**Features:**
- Connect with or without session authentication
- Join public channels (no auth required)
- Join secure channels (auth required)
- Send custom events
- View real-time messages

### Channel Types

**Public Channels** (`public:*`)
- No authentication required
- Example: `public:lobby`
- Auto-joins on connection in test page

**Secure Channels** (`secure:*`)
- Requires valid session authentication
- Example: `secure:user_room`
- Only accessible with `X-Session-Id` header or `session_id` query param

### WebSocket Authentication

Pass session ID via query parameter:

```javascript
const socket = new Phoenix.Socket("/socket", {
  params: {session_id: "your-session-id-here"}
});
```

Or use the test page at `/ws` which handles authentication automatically.

## 📚 Documentation

Comprehensive documentation is available in the `/docs` directory:

- **[00-ARCHITECTURE-OVERVIEW.md](./docs/00-ARCHITECTURE-OVERVIEW.md)** - System architecture and components
- **[02-CORE-CONCEPTS.md](./docs/02-CORE-CONCEPTS.md)** - Core concepts with examples
- **[03-ENVIRONMENT.md](./docs/03-ENVIRONMENT.md)** - Environment configuration guide
- **[04-USAGE-GUIDE.md](./docs/04-USAGE-GUIDE.md)** - Complete usage examples
- **[QUICK-REFERENCE.md](./docs/QUICK-REFERENCE.md)** - Quick reference guide

## 📖 Usage Examples

### Public Route (No Authentication)

```elixir
# In router.ex
scope "/api", MyAppWeb do
  pipe_through :api
  get "/hello", MyController, :hello
end

# In controller
def hello(conn, _params) do
  json(conn, %{message: "Hello, world!"})
end
```

### Protected Route (Authentication Required)

```elixir
# In router.ex
scope "/api/secure", MyAppWeb do
  pipe_through :api_auth
  get "/profile", MyController, :profile
end

# In controller
def profile(conn, _params) do
  claims = conn.assigns[:auth_claims]
  json(conn, %{
    user_id: claims["user_id"],
    email: claims["email"],
    name: claims["name"]
  })
end
```

### Optional Authentication

```elixir
# Uses :api pipeline (OptionalMiddleware)
scope "/api", MyAppWeb do
  pipe_through :api
  get "/content", MyController, :content
end

# In controller
def content(conn, _params) do
  claims = conn.assigns[:auth_claims]
  
  if claims do
    json(conn, %{message: "Hello, #{claims["name"]}"})
  else
    json(conn, %{message: "Hello, guest"})
  end
end
```

### Admin-Only Route

```elixir
scope "/api/secure", MyAppWeb do
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

### Database Operations

```elixir
alias MyApp.Repo
alias MyApp.Models.User

# Query all users
users = Repo.all(User)

# Get by ID
user = Repo.get(User, "user-id")

# Query with filter
import Ecto.Query
active_users = from(u in User, where: u.active == true) |> Repo.all()

# Insert
%User{id: "new-id", email: "test@example.com"} |> Repo.insert()

# Handle optional DB
try do
  users = Repo.all(User)
  json(conn, users)
rescue
  RuntimeError ->
    conn
    |> put_status(503)
    |> json(%{error: "database not configured"})
end
```

### WebSocket Channel

```elixir
defmodule MyAppWeb.ChatChannel do
  use MyAppWeb, :channel

  # Public channel
  def join("chat:lobby", _payload, socket) do
    {:ok, socket}
  end

  # Secure channel (auth required)
  def join("chat:private", _payload, socket) do
    if socket.assigns[:auth_claims] do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast!(socket, "new_msg", %{body: body})
    {:noreply, socket}
  end
end
```

## 🔧 Development

### Code Quality

```bash
# Format code
mix format

# Check for compilation warnings
mix compile --warnings-as-errors

# Run precommit checks (format + tests)
mix precommit
```

### Testing

```bash
# Run all tests (no database required)
mix test

# Run specific test file
mix test test/flowfull_elixir_starter_web/controllers/page_controller_test.exs

# Run with verbose output
mix test --trace
```

**Note:** Tests run without database by default. If you need to test DB-dependent features, ensure `DATABASE_URL` is not set in test environment or use a SQLite database for testing.

**Coverage:** This starter template includes basic tests. You can add more comprehensive tests for your application as needed.

## 🏗️ Project Structure

```
flowfull_elixir_starter/
├── lib/
│   ├── flowfull_elixir_starter/
│   │   ├── auth/
│   │   │   ├── bridge_validator.ex   # Session validation
│   │   │   ├── middleware.ex         # Required auth
│   │   │   └── optional_middleware.ex # Optional auth
│   │   ├── models/
│   │   │   └── user.ex               # User model
│   │   └── repo.ex                   # Database repo
│   ├── flowfull_elixir_starter_web/
│   │   ├── channels/
│   │   │   ├── public_channel.ex     # Public WS channel
│   │   │   └── secure_channel.ex     # Secure WS channel
│   │   ├── controllers/
│   │   │   ├── page_controller.ex    # Pages (/ws test)
│   │   │   └── sample_controller.ex  # API routes
│   │   ├── endpoint.ex               # HTTP endpoint
│   │   ├── router.ex                 # Route definitions
│   │   └── user_socket.ex            # WebSocket handler
├── config/
│   ├── config.exs                    # Compile-time config
│   ├── dev.exs                       # Dev config
│   ├── test.exs                      # Test config
│   └── runtime.exs                   # Runtime config (Dotenvy)
├── priv/
│   └── repo/
│       └── migrations/               # Database migrations
├── test/                             # Tests
├── docs/                             # Documentation
├── .env.example                      # Environment template
└── mix.exs                           # Project definition
```

## 🔐 Security

### Authentication Headers

```bash
# Send session ID in header
curl http://localhost:4000/api/secure/profile \
  -H "X-Session-Id: your-session-id-here"

# Or use cookie (alternative)
curl http://localhost:4000/api/secure/profile \
  -H "Cookie: session_id=your-session-id-here"
```

**Note:** Header names are automatically normalized to lowercase by Plug (`X-Session-Id` → `x-session-id`).

### Development Mode

For local development without Flowless:

```env
DEV_ALLOW_BRIDGE_STUB=1
```

This bypasses real bridge validation and returns mock user data.

## 🚀 Deployment

### Environment Variables

Required for production:

```env
FLOWLESS_API_URL=https://your-instance.pubflow.com
BRIDGE_VALIDATION_SECRET=your-production-secret-min-32-chars
DATABASE_URL=postgresql://user:pass@host:5432/db
SECRET_KEY_BASE=your-phoenix-secret-key-base
PORT=4000
```

### Generate Secret Key Base

```bash
mix phx.gen.secret
```

### Production Server

```bash
# Build release
MIX_ENV=prod mix release

# Run release
_build/prod/rel/flowfull_elixir_starter/bin/flowfull_elixir_starter start
```

Or use Docker for deployment.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and formatting (`mix test && mix format`)
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Links

- **Flowless Documentation**: [Flowless Docs](https://docs.pubflow.com)
- **Phoenix Documentation**: [Phoenix Framework](https://www.phoenixframework.org/)
- **Elixir Documentation**: [Elixir Lang](https://elixir-lang.org/)
- **Ecto Documentation**: [Ecto](https://hexdocs.pm/ecto/)

## 💬 Support

For issues and questions:
- Open an issue on GitHub
- Check the documentation in `/docs` directory
- Contact: support@pubflow.com

---

**Built with ❤️ by the Pubflow Team**
