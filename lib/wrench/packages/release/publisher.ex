defmodule Wrench.Packages.Release.Publisher do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :email, :string
    field :url, :string
    field :username, :string
  end

  @doc false
  def changeset(pub \\ %__MODULE__{}, attrs) do
    pub
    |> cast(attrs, [
      :email,
      :url,
      :username
    ])
  end
end
