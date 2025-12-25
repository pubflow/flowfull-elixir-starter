# Environment Configuration

Create `.env` from `.env.example` and set the following:

## Required Variables

- `FLOWLESS_API_URL`: URL of your Flowless instance (e.g., `https://api.pubflow.com`)
- `BRIDGE_VALIDATION_SECRET`: Shared secret for bridge validation (min 32 chars)

## Optional Variables

- `DATABASE_URL`: Database connection string
  - PostgreSQL: `postgresql://user:pass@localhost:5432/dbname?sslmode=verify-full`
  - CockroachDB: `postgresql://user:pass@host:26257/dbname?sslmode=verify-full`
  - MySQL: `mysql://user:pass@localhost:3306/dbname`
  - SQLite: `sqlite://path/to/database.db`

- `DEV_ALLOW_BRIDGE_STUB`: Set to `1` to bypass real Flowless validation in development
- `SESSION_HEADER_NAME`: Custom header name for session ID (default: `x-session-id`)
- `SESSION_COOKIE_NAME`: Custom cookie name for session ID (default: `session_id`)
- `PORT`: HTTP server port (default: `4000`)
- `POOL_SIZE`: Database connection pool size (default: `10`)

## Minimum Example

```env
FLOWLESS_API_URL=https://api.pubflow.com
BRIDGE_VALIDATION_SECRET=your-shared-secret-min-32-chars-long
```

## Development Example with Database

```env
FLOWLESS_API_URL=https://api.pubflow.com
BRIDGE_VALIDATION_SECRET=your-shared-secret-min-32-chars-long
DATABASE_URL=postgresql://flowless:password@localhost:5432/flowfull_dev
DEV_ALLOW_BRIDGE_STUB=1
```

## CockroachDB Configuration

CockroachDB requires SSL. The starter automatically configures SSL with proper certificate verification:

```env
DATABASE_URL=postgresql://user:pass@host:26257/defaultdb?sslmode=verify-full
```

SSL options are automatically set in `config/runtime.exs`:
- `ssl: true` with certificate verification
- Uses system CA certificates via `:public_key.cacerts_get()`
- Verifies server hostname

## Apply Migrations

```bash
# Create migration
mix ecto.gen.migration create_users

# Run migrations
mix ecto.migrate

# Rollback
mix ecto.rollback
```

## Start the Server

```bash
# Install dependencies
mix deps.get

# Compile assets
mix assets.setup

# Start development server
mix phx.server

# Or start with IEx shell
iex -S mix phx.server
```

Access at: `http://localhost:4000`

## Tips

- Header names are automatically normalized to lowercase by Plug (e.g., `X-Session-Id` becomes `x-session-id`)
- Database is optional — Repo only starts if `DATABASE_URL` is set
- Use `DEV_ALLOW_BRIDGE_STUB=1` for local development without running Flowless
- Keep `.env` out of version control (already in `.gitignore`)
