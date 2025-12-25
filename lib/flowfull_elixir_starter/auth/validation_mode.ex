defmodule FlowfullElixirStarter.Auth.ValidationMode do
  @modes [:disabled, :standard, :advanced, :strict]

  def current do
    case System.get_env("VALIDATION_MODE") do
      nil -> :standard
      mode -> String.to_atom(mode)
    end
  end

  def modes, do: @modes
end
