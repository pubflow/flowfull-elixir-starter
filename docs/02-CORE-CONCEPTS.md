# Core Concepts

Below are the core concepts with purpose, location, quick usage, and tips.

## 1. Bridge Validation
- **Purpose**: Validate sessions against Flowless and extract user claims.
- **Location**: `lib/flowfull_elixir_starter/auth/bridge_validator.ex`
- **Usage**: `BridgeValidator.validate_session_id(session_id)` returns `{:ok, claims}` or `{:error, reason}`
- **Tips**: 
  - Always include `X-Session-Id` header in requests
  - Set `DEV_ALLOW_BRIDGE_STUB=1` in `.env` for local development without real Flowless
  - Bridge validation posts to `FLOWLESS_API_URL/auth/bridge/validate` with `X-Bridge-Secret` header

## 2. Auth Middleware
- **Purpose**: Protect routes and inject user claims into conn.assigns
- **Location**: `lib/flowfull_elixir_starter/auth/middleware.ex` (required), `optional_middleware.ex` (optional)
- **Patterns**:
  - **Required auth**: Use `:api_auth` pipeline — returns 401 if session invalid
  - **Optional auth**: Use `:api` pipeline — assigns claims if present, continues if not
- **Usage**:
  ```elixir
  # In controller
  def protected(conn, _params) do
    claims = conn.assigns[:auth_claims]
    # claims contains user_id, email, name, user_type, etc.
  end
  ```
- **Tips**: Check `user_type` in claims for admin-only routes

## 3. Plugs and Pipelines
- **Purpose**: Composable request processing
- **Location**: `lib/flowfull_elixir_starter_web/router.ex`
- **Pipelines**:
  - `:browser` - HTML pages with CSRF protection
  - `:api` - JSON API with optional auth (`OptionalMiddleware`)
  - `:api_auth` - JSON API with required auth (`Middleware`)
- **Tips**: Prefer creating new pipelines over adding plugs directly to routes

## 4. Ecto and Database
- **Purpose**: Database access and schema management
- **Location**: 
  - Repository: `lib/flowfull_elixir_starter/repo.ex`
  - Schemas: `lib/flowfull_elixir_starter/models/`
- **Usage**:
  ```elixir
  alias FlowfullElixirStarter.Repo
  alias FlowfullElixirStarter.Models.User
  
  # Query all users
  users = Repo.all(User)
  
  # Get by ID
  user = Repo.get(User, "user-id")
  
  # Insert
  %User{id: "new-id", email: "test@example.com"}
  |> Repo.insert()
  ```
- **Tips**: 
  - Repo only starts if `DATABASE_URL` is set
  - Wrap Repo calls in try/rescue for graceful degradation
  - Use SSL configuration for CockroachDB and production databases

## 5. Phoenix Channels (WebSockets)
- **Purpose**: Real-time bidirectional communication
- **Location**: 
  - Socket: `lib/flowfull_elixir_starter_web/user_socket.ex`
  - Channels: `lib/flowfull_elixir_starter_web/channels/`
- **Patterns**:
  - **Public channels** (`public:*`): No auth required
  - **Secure channels** (`secure:*`): Require valid `auth_claims` in socket assigns
- **Usage**:
  ```elixir
  # In channel
  def join("secure:lobby", _payload, socket) do
    if socket.assigns[:auth_claims] do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end
  ```
- **Tips**: 
  - Test with `/ws` page in browser
  - Session validation happens in `UserSocket.connect/3`
  - Use `push/3` to send messages to client, `broadcast/3` for all subscribers

## 6. Environment Configuration
- **Purpose**: Load configuration from .env files at runtime
- **Location**: `config/runtime.exs`
- **Required vars**:
  - `FLOWLESS_API_URL` - Flowless API endpoint (e.g., `https://api.pubflow.com`)
  - `BRIDGE_VALIDATION_SECRET` - Shared secret for bridge validation
- **Optional vars**:
  - `DATABASE_URL` - Database connection string
  - `DEV_ALLOW_BRIDGE_STUB` - Allow stub auth in development (`1` to enable)
  - `SESSION_HEADER_NAME` - Custom session header name (default: `x-session-id`)
  - `SESSION_COOKIE_NAME` - Custom session cookie name (default: `session_id`)
  - `PORT` - HTTP port (default: `4000`)
- **Tips**: 
  - Use Dotenvy for .env loading in all environments
  - System.get_env/1 works after Dotenvy propagation
  - Keep secrets out of version control

## 7. Error Handling
- **Purpose**: Graceful error responses
- **Patterns**:
  - Middleware returns 401 for auth failures
  - Controllers return 403 for authorization failures (wrong user_type)
  - Controllers return 404 for not found resources
  - Controllers return 503 for database unavailable
- **Usage**:
  ```elixir
  conn
  |> put_status(403)
  |> json(%{error: "forbidden"})
  ```
- **Tips**: Always provide clear error messages for debugging
