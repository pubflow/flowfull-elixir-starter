defmodule FlowfullElixirStarter.Auth.BridgeValidator do
  @moduledoc """
  Bridge Validation - Distributed session validation with Flowless

  This module implements the Bridge Validation pattern for validating sessions
  with the Flowless authentication service.
  """

  require Logger

  def validate_session(%{"user_id" => user_id}) when is_binary(user_id) do
    allow_stub? = allow_stub?()

    case System.get_env("FLOWLESS_API_URL") do
      nil when allow_stub? ->
        Logger.warning(
          "FLOWLESS_API_URL not configured; DEV_ALLOW_BRIDGE_STUB enabled -> treating claims as validated"
        )

        :ok

      nil ->
        Logger.error("FLOWLESS_API_URL not configured and DEV_ALLOW_BRIDGE_STUB is false")
        {:error, :no_bridge}

      base ->
        with secret when secret not in [nil, ""] <- System.get_env("BRIDGE_VALIDATION_SECRET"),
             {:ok, %{status: 200, body: data}} when is_map(data) <-
               Req.post(
                 url: base <> "/auth/bridge/validate",
                 json: %{user_id: user_id},
                 headers: bridge_headers(secret)
               ) do
          cond do
            data["success"] == true and data["valid"] != false ->
              :ok

            true ->
              Logger.warning("Session validation rejected: #{inspect(data)}")
              {:error, :bridge_invalid}
          end
        else
          nil ->
            Logger.error("BRIDGE_VALIDATION_SECRET not configured")
            {:error, :no_secret}

          {:ok, %{status: status, body: body}} ->
            Logger.warning("Bridge validation failed: status=#{status}, body=#{inspect(body)}")
            {:error, {:bridge_status, status}}

          {:error, %{reason: :timeout}} ->
            Logger.error("Bridge validation timeout")
            {:error, :timeout}

          {:error, reason} ->
            Logger.error("Bridge validation error: #{inspect(reason)}")
            {:error, :bridge_error}
        end
    end
  end

  def validate_session(_), do: {:error, :invalid_claims}

  def validate_session_id(session_id, opts \\ %{})

  def validate_session_id(session_id, opts) when is_binary(session_id) do
    allow_stub? = allow_stub?()

    case System.get_env("FLOWLESS_API_URL") do
      nil when allow_stub? ->
        Logger.warning(
          "FLOWLESS_API_URL not configured; DEV_ALLOW_BRIDGE_STUB enabled -> using dev stub claims"
        )

        {:ok, dev_stub_claims(session_id)}

      nil ->
        Logger.error("FLOWLESS_API_URL not configured and DEV_ALLOW_BRIDGE_STUB is false")
        {:error, :no_bridge}

      base ->
        secret = System.get_env("BRIDGE_VALIDATION_SECRET")

        if is_nil(secret) or secret == "" do
          Logger.error("BRIDGE_VALIDATION_SECRET not configured")
          {:error, :no_secret}
        else
          payload =
            %{session_id: session_id}
            |> maybe_put(:ip, opts[:ip])
            |> maybe_put(:user_agent, opts[:user_agent])
            |> maybe_put(:device_id, opts[:device_id])

          Logger.info("Validating session: #{String.slice(session_id, 0..7)}...")

          case Req.post(
                 url: base <> "/auth/bridge/validate",
                 json: payload,
                 headers: bridge_headers(secret)
               ) do
            {:ok, %{status: 200, body: data}} when is_map(data) ->
              success? = data["success"] == true
              valid? = data["valid"]

              cond do
                success? and valid? == false ->
                  Logger.warning(
                    "Session validation rejected (valid=false): session_id=#{String.slice(session_id, 0..7)}..."
                  )

                  {:error, :session_invalid}

                success? ->
                  case data["user"] do
                    nil ->
                      Logger.error("Session validation missing user data")
                      {:error, :missing_user_data}

                    user_data ->
                      claims = %{
                        "user_id" => user_data["id"] || user_data["user_id"],
                        "email" => user_data["email"] || "",
                        "name" => user_data["name"] || "",
                        "user_type" => user_data["user_type"],
                        "organization_id" => user_data["organization_id"],
                        "permissions" => user_data["permissions"],
                        "picture" => user_data["picture"] || user_data["avatar"],
                        "is_verified" => user_data["is_verified"] || user_data["isVerified"],
                        "session_id" => session_id
                      }

                      Logger.info(
                        "Session validated: user_id=#{claims["user_id"]}, email=#{claims["email"]}"
                      )

                      {:ok, claims}
                  end

                true ->
                  Logger.warning(
                    "Session validation rejected: success=#{data["success"]}, valid=#{data["valid"]}"
                  )

                  {:error, :session_invalid}
              end

            {:ok, %{status: status, body: body}} ->
              Logger.warning("Bridge validation failed: status=#{status}, body=#{inspect(body)}")
              {:error, {:bridge_status, status}}

            {:error, %{reason: :timeout}} ->
              Logger.error("Bridge validation timeout")
              {:error, :timeout}

            {:error, reason} ->
              Logger.error("Bridge validation error: #{inspect(reason)}")
              {:error, :bridge_error}
          end
        end
    end
  end

  def validate_session_id(_, _), do: {:error, :invalid_session_id}

  defp bridge_headers(secret) do
    [
      {"X-Bridge-Secret", secret},
      {"Content-Type", "application/json"}
    ]
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp allow_stub? do
    System.get_env("DEV_ALLOW_BRIDGE_STUB") in ["1", "true", "TRUE", "yes", "YES"]
  end

  defp dev_stub_claims(session_id) do
    %{
      "user_id" => "dev-user",
      "email" => "dev@example.com",
      "name" => "Dev User",
      "session_id" => session_id
    }
  end
end
