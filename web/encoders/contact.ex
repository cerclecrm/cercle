defimpl Poison.Encoder, for: CercleApi.Contact do
  def encode(model, opts) do
    model
      |> Map.take([:name, :id, :email, :phone])
      |> Poison.Encoder.encode(opts)
  end
end