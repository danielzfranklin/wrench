defmodule Wrench.Packages.Link do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :title, :string
    field :value, :string
  end

  @doc false
  def changeset(link \\ %__MODULE__{}, attrs) do
    link
    |> cast(attrs, [
      :title,
      :value
    ])
    |> validate_required([:title, :value])
  end
end
