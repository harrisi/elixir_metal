defmodule ElixirMetal.MetalRenderer do
  @on_load :load_nif

  def load_nif do
    nif_file = :filename.join(:code.priv_dir(:elixir_metal), "metal_renderer")
    case :erlang.load_nif(to_charlist(nif_file), 0) do
      :ok -> :ok
      {:error, {:load_failed, reason}} ->
        IO.puts("Failed to load NIF: #{inspect(reason)}")
        :error
    end
  end

  def create_metal_renderer(handle) do
    create_metal_renderer(handle, :code.priv_dir(:elixir_metal))
  end

  def create_metal_renderer(_handle, _priv_dir), do: :erlang.nif_error(:nif_not_loaded)
  def resize_metal_renderer(_renderer, _width, _height), do: :erlang.nif_error(:nif_not_loaded)
  def render_frame(_renderer), do: :erlang.nif_error(:nif_not_loaded)
end
