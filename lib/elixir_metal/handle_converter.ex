defmodule ElixirMetal.HandleConverter do
  @on_load :load_nif

  def load_nif do
    nif_file = Path.join(:code.priv_dir(:elixir_metal), "handle_converter")

    case :erlang.load_nif(nif_file, :load_nif) do
      :ok -> :ok
      {:error, reason} ->
        {:error, "Failed to load NIF: #{inspect(reason)}"}
    end
  end

  def convert_to_native_handle(_handle) do
    :erlang.nif_error(:nif_not_loaded)
  end
end
