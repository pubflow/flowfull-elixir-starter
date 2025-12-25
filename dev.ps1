Write-Host "🚀 Flowfull Elixir Starter - Development Mode" -ForegroundColor Cyan

if (-Not (Test-Path ".env")) {
  Write-Host "⚠️  .env file not found!" -ForegroundColor Yellow
  Copy-Item ".env.example" ".env"
  Write-Host "✅ .env file created!" -ForegroundColor Green
  Write-Host "Edit .env before running." -ForegroundColor Yellow
  Read-Host
}

Write-Host "📦 Installing dependencies..." -ForegroundColor Cyan
mix deps.get

Write-Host "🔥 Starting server (Ctrl+C to stop)" -ForegroundColor Cyan
mix run --no-halt
