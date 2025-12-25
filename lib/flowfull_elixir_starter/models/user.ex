defmodule FlowfullElixirStarter.Models.User do
  @moduledoc """
  User Model - Example Ecto schema

  This is an example model to demonstrate database usage.
  Customize or remove based on your application needs.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string

  schema "users" do
    field :email, :string
    field :name, :string
    field :last_name, :string
    field :user_type, :string, default: "user"
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :email, :name, :last_name, :user_type])
    |> validate_required([:id, :email])
    |> unique_constraint(:email)
  end
end
