defmodule Wrench.Packages.Release.Retirement do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :reason, :string
    field :message, :string
  end

  @doc false
  def changeset(ret \\ %__MODULE__{}, attrs) do
    ret
    |> cast(attrs, [
      :reason,
      :message
    ])
  end
end
