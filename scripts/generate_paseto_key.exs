require Logger

{:ok, priv, pub} = :crypto.generate_key(:eddsa, :ed25519)

IO.puts("===========================================")
IO.puts("🔑 PASETO v4 Key Pair Generated")
IO.puts("===========================================")
IO.puts("")
IO.puts("📢 Public Key:")
IO.puts(Base.encode16(pub, case: :lower))
IO.puts("")
IO.puts("🔒 Private Key (add this to your .env file):")
IO.puts(Base.encode16(priv, case: :lower))
IO.puts("")
IO.puts("📝 Add to .env:")
IO.puts("PASETO_PRIVATE_KEY=" <> Base.encode16(priv, case: :lower))
IO.puts("")
IO.puts("⚠️  Keep the private key secret!")
IO.puts("===========================================")
