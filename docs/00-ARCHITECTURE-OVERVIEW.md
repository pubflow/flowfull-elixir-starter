# Architecture Overview

This starter aims to be productive, clear, and robust for Elixir/Phoenix development:

- Phoenix 1.8+ with Bandit web server
- Auth middleware based on Bridge Validation (Flowless)
- Ecto 3.x for multi-dialect databases
- Phoenix Channels for WebSocket support with auth integration
- Configuration via Dotenvy for .env file loading

## Components
- `lib/flowfull_elixir_starter_web/endpoint.ex`: HTTP endpoint configuration
- `lib/flowfull_elixir_starter_web/router.ex`: Route definitions with pipeline-based auth
- `lib/flowfull_elixir_starter/auth/`: session validation (Flowless), middleware (required/optional)
- `lib/flowfull_elixir_starter/repo.ex`: Ecto repository for database operations
- `lib/flowfull_elixir_starter/models/`: Ecto schemas (e.g., `User`)
- `lib/flowfull_elixir_starter_web/channels/`: WebSocket channels (public and secure)

## Authentication Flow
1. Client sends `X-Session-Id` header with requests.
2. Middleware validates against Flowless `/auth/bridge/validate` using `X-Bridge-Secret`.
3. If valid, claims map is injected into `conn.assigns[:auth_claims]`.
4. WebSocket connections can validate sessions and assign claims to socket assigns.

## Supported Databases
- PostgreSQL (including CockroachDB with SSL)
- MySQL
- SQLite
Configure via `DATABASE_URL` in `.env`. The Repo only starts if `DATABASE_URL` is set.

## Request Lifecycle (High-Level)
- Incoming request → Phoenix pipeline → middleware parses headers → (optional) session validation → controller action → DB access via `Repo` → JSON response

## WebSocket Flow
- Client connects to `/socket` with optional `session_id` query param or header
- `UserSocket.connect/3` validates session if present, assigns `auth_claims` on success
- Public channels (`public:*`) work without authentication
- Secure channels (`secure:*`) require valid `auth_claims` in socket assigns

## Extending the Architecture
- Add new routes in `router.ex` using `:api` pipeline (optional auth) or `:api_auth` (required auth).
- Define new models in `lib/flowfull_elixir_starter/models/` as Ecto schemas.
- Create new channels in `lib/flowfull_elixir_starter_web/channels/` and register in `user_socket.ex`.
- Create migrations with `mix ecto.gen.migration migration_name`.
