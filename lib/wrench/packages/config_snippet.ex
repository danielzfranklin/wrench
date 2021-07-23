defmodule Wrench.Packages.ConfigSnippet do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :tool, :string
    field :value, :string
  end

  @doc false
  def changeset(snippet \\ %__MODULE__{}, attrs) do
    snippet
    |> cast(attrs, [
      :tool,
      :value
    ])
    |> validate_required([:tool, :value])
  end
end
