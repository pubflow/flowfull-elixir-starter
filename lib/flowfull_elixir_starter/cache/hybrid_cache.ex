defmodule FlowfullElixirStarter.Cache.HybridCache do
  @moduledoc false

  def get(key, db_fallback) when is_function(db_fallback, 0) do
    case Cachex.get(:hybrid_cache, key) do
      {:ok, nil} ->
        case maybe_redis_get(key) do
          nil ->
            val = db_fallback.()
            put(key, val)
            val

          v ->
            v
        end

      {:ok, v} ->
        v
    end
  end

  def put(key, value) do
    Cachex.put(:hybrid_cache, key, value)
    maybe_redis_set(key, value)
    value
  end

  defp maybe_redis_get(key) do
    case Process.whereis(:redis) do
      nil ->
        nil

      _pid ->
        case Redix.command(:redis, ["GET", key]) do
          {:ok, nil} ->
            nil

          {:ok, v} ->
            case v do
              nil ->
                nil

              bin when is_binary(bin) ->
                case Jason.decode(bin) do
                  {:ok, decoded} -> decoded
                  _ -> bin
                end

              other ->
                other
            end

          _ ->
            nil
        end
    end
  end

  defp maybe_redis_set(key, value) do
    case Process.whereis(:redis) do
      nil ->
        :ok

      _pid ->
        _ = Redix.command(:redis, ["SET", key, Jason.encode!(value)])
        :ok
    end
  end
end
