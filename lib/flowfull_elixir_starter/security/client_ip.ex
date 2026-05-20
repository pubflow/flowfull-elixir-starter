defmodule FlowfullElixirStarter.Security.ClientIP do
  @moduledoc """
  Proxy-aware client IP extraction for Traefik, Coolify, Nginx, and Cloudflare.
  """

  import Plug.Conn

  @headers [
    "cf-connecting-ip",
    "true-client-ip",
    "fly-client-ip",
    "x-real-ip",
    "x-client-ip",
    "x-forwarded-for",
    "forwarded"
  ]

  def from_conn(conn) do
    header_ip =
      Enum.find_value(@headers, fn header ->
        conn
        |> get_req_header(header)
        |> List.first()
        |> first_header_ip()
      end)

    header_ip || remote_ip(conn)
  end

  defp first_header_ip(nil), do: nil

  defp first_header_ip(value) do
    value
    |> String.split(",", parts: 2)
    |> List.first()
    |> normalize_ip()
  end

  defp normalize_ip(nil), do: nil

  defp normalize_ip(value) do
    normalized =
      value
      |> String.trim()
      |> strip_quotes()
      |> strip_forwarded_prefix()
      |> strip_forwarded_params()
      |> strip_quotes()
      |> strip_port()
      |> String.downcase()
      |> strip_ipv4_mapped_ipv6()
      |> normalize_loopback()

    if valid_ip?(normalized), do: normalized, else: nil
  end

  defp strip_forwarded_prefix(value) do
    if String.starts_with?(String.downcase(value), "for=") do
      value
      |> String.slice(4..-1//1)
      |> String.trim()
      |> strip_quotes()
    else
      value
    end
  end

  defp strip_quotes(value) do
    value = String.trim(value)

    cond do
      String.starts_with?(value, "\"") and String.ends_with?(value, "\"") ->
        value |> String.trim_leading("\"") |> String.trim_trailing("\"")

      String.starts_with?(value, "'") and String.ends_with?(value, "'") ->
        value |> String.trim_leading("'") |> String.trim_trailing("'")

      true ->
        value
    end
  end

  defp strip_forwarded_params(value) do
    value
    |> String.split(";", parts: 2)
    |> List.first()
    |> String.trim()
  end

  defp strip_port("[" <> rest) do
    case String.split(rest, "]", parts: 2) do
      [ip, _] -> ip
      _ -> "[" <> rest
    end
  end

  defp strip_port(value) do
    if String.contains?(value, ".") and length(String.split(value, ":")) == 2 do
      value |> String.split(":", parts: 2) |> List.first()
    else
      value
    end
  end

  defp strip_ipv4_mapped_ipv6("::ffff:" <> ipv4), do: ipv4
  defp strip_ipv4_mapped_ipv6(value), do: value

  defp normalize_loopback("::1"), do: "127.0.0.1"
  defp normalize_loopback(value), do: value

  defp valid_ip?(value) do
    match?({:ok, _}, :inet.parse_address(String.to_charlist(value)))
  end

  defp remote_ip(%Plug.Conn{remote_ip: remote_ip}) when is_tuple(remote_ip) do
    remote_ip
    |> :inet.ntoa()
    |> to_string()
    |> normalize_ip()
  end

  defp remote_ip(_conn), do: nil
end
