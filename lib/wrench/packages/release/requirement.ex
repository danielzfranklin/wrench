defmodule Wrench.Packages.Release.Requirement do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :app, :string
    field :optional, :boolean, default: false
    field :requirement, :string
  end

  @doc false
  def changeset(req \\ %__MODULE__{}, attrs) do
    req
    |> cast(attrs, [
      :app,
      :optional,
      :requirement
    ])
    |> validate_required([:app, :optional, :requirement])
  end
end
