# elixir phoenix にエンドポイントを手動で追加する

1. Schema 定義

```elixir
defmodule FirstPhoenixApi.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string

    timestamps(type: :utc_datetime)
  end

  # validation等
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
    |> validate_length(:name, min: 3)
  end
end
```

2. Context 窓口
