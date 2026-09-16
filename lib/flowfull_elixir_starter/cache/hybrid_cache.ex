defmodule FlowfullElixirStarter.Cache.HybridCache do
  @moduledoc """
  Exclusive cache backend: Redis when the `:redis` process exists, otherwise Cachex.
  Never dual-writes or backfills the other store.
  """

  def get(key, db_fallback) when is_function(db_fallback, 0) do
    if redis_enabled?() do
      case maybe_redis_get(key) do
        nil ->
          val = db_fallback.()
          maybe_redis_set(key, val)
          val

        v ->
          v
      end
    else
      case Cachex.get(:hybrid_cache, key) do
        {:ok, nil} ->
          val = db_fallback.()
          Cachex.put(:hybrid_cache, key, val)
          val

        {:ok, v} ->
          v
      end
    end
  end

  def put(key, value) do
    if redis_enabled?() do
      maybe_redis_set(key, value)
    else
      Cachex.put(:hybrid_cache, key, value)
    end

    value
  end

  def delete(key) do
    if redis_enabled?() do
      _ = Redix.command(:redis, ["DEL", key])
    else
      Cachex.del(:hybrid_cache, key)
    end

    :ok
  end

  defp redis_enabled? do
    Process.whereis(:redis) != nil
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
