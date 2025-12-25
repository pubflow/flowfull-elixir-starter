defmodule FlowfullElixirStarter.Tokens.TrustTokens do
  @moduledoc """
  Trust Tokens - PASETO v4 token management (placeholder)

  Session validation happens via BridgeValidator.
  PASETO tokens are not used in this starter template.
  """

  def sign(claims, ttl_seconds) do
    now = DateTime.utc_now()
    exp = DateTime.add(now, ttl_seconds, :second)
    full_claims = Map.merge(%{"iat" => now, "exp" => exp}, claims)

    key_hex = System.get_env("PASETO_PRIVATE_KEY")

    with {:ok, key} <- decode_ed25519_key(key_hex),
         {:ok, token} <- paseto_sign(full_claims, key) do
      {:ok, token}
    else
      _ -> {:error, :sign_failed}
    end
  end

  def verify(_token) do
    # Placeholder: Session validation uses BridgeValidator
    {:error, :paseto_not_configured}
  end

  defp decode_ed25519_key(nil), do: {:error, :no_key}

  defp decode_ed25519_key(hex) do
    case Base.decode16(hex, case: :mixed) do
      {:ok, bin} -> {:ok, bin}
      _ -> {:error, :bad_key}
    end
  end

  defp paseto_sign(_claims, _key) do
    # Placeholder: Integrate PASETO library for production
    {:error, :paseto_not_configured}
  end
end
