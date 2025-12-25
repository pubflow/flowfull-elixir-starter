defmodule FlowfullElixirStarter.Models.Task do
  use Ecto.Schema
  import Ecto.Changeset
  alias FlowfullElixirStarter.Repo

  schema "tasks" do
    field :title, :string
    field :done, :boolean, default: false
    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :done])
    |> validate_required([:title])
  end

  def list do
    Repo.all(__MODULE__)
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
