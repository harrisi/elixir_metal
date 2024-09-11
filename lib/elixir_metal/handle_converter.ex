defmodule ElixirMetal.HandleConverter do
  @moduledoc """
  Converts between Erlang and native handles.
  """
  @on_load :load_nif

  def load_nif do
    nif_file = Path.join(:code.priv_dir(:elixir_metal), "handle_converter")

    case :erlang.load_nif(nif_file, :load_nif) do
      :ok -> :ok
      {:error, reason} ->
        {:error, "Failed to load NIF: #{inspect(reason)}"}
    end
  end

  @doc """
  Converts an Erlang handle to a native handle.
  """
  def convert_to_native_handle(_handle) do
    :erlang.nif_error(:nif_not_loaded)
  end
end
