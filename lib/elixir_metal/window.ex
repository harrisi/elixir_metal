defmodule ElixirMetal.Window do
  require Logger
  import WxEx.Constants
  import WxEx.Records

  @behaviour :wx_object

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      # type: :worker,
      significant: true,
      restart: :temporary,
      # shutdown: 500
    }
  end

  def start(_, _) do
    :wx_object.start_link(__MODULE__, [], [])
  end

  def start_link(_args) do
    :wx_object.start_link({:local, __MODULE__}, __MODULE__, [], [])

    {:ok, self()}
  end

  @impl :wx_object
  def terminate(reason, state) do
    Logger.error(msg: reason)
    IO.inspect(reason, label: "terminate")
    Supervisor.stop(ElixirMetal.Supervisor)

    {:shutdown, state}
  end

  @impl :wx_object
  def init(_) do
    opts = [size: {640, 480}]
    wx = :wx.new()
    frame = :wxFrame.new(wx, wxID_ANY(), ~c'Elixir Metal', opts)
    panel = :wxPanel.new(frame)

    :wxWindow.connect(panel, :paint)
    # :wxWindow.connect(frame, :idle)

    :wxFrame.connect(panel, :size)
    :wxWindow.show(frame)
    # :wxWindow.show(panel)

    handle = :wxWindow.getHandle(panel)

    case ElixirMetal.HandleConverter.convert_to_native_handle(handle) do
      {:ok, native_handle} ->
        IO.puts("Native handle created successfully: #{inspect(native_handle, base: :hex)}")
        case ElixirMetal.MetalRenderer.create_metal_renderer(native_handle) do
          {:ok, renderer} ->
            IO.puts("Metal renderer created successfully")
            Process.send_after(self(), :render, 16)
            {frame, %{renderer: renderer, panel: panel, frame: frame}}
          {:error, reason} ->
            IO.puts("Failed to create Metal renderer: #{inspect(reason)}")
            {:stop, reason}
        end
      {:error, reason} ->
        IO.puts("Failed to create native handle: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl :wx_object
  def handle_event(wx(event: wxSize(type: :size, size: {width, height})) = _event, state) do
    IO.puts("Window resized to #{width}x#{height}")
    :ok = ElixirMetal.MetalRenderer.resize_metal_renderer(state.renderer, width, height)
    {:noreply, state}
  end

  # @impl :wx_object
  # def handle_event(wx(obj: obj, event: wxIdle() = ie) = event, state) do
  #   IO.inspect(event, label: "event")
  #   send(self(), :render)
  #   :wxIdleEvent.requestMore(ie)

  #   {:noreply, state}
  # end

  @impl :wx_object
  def handle_event(wx(obj: obj, event: wxPaint(type: type)) = _event, state) do
    IO.inspect(type, label: "type")
    # Must do a PaintDC and destroy it
    dc = :wxPaintDC.new(obj)
    :wxPaintDC.destroy(dc)

    {:noreply, state}
  end

  @impl :wx_object
  def handle_event(wx(obj: obj, event: wxClose(type: :close_window)) = info, state) do
    IO.inspect(wx(info))

    :wxWindow."Destroy"(obj)

    {:stop, :normal, state}
  end

  @impl :wx_object
  def handle_event(event, state) do
    IO.inspect(event, label: "unknown event")

    {:noreply, state}
  end

  @impl :wx_object
  def handle_info(:render, state) do
    # cur_env = :wx.get_env()
    # cur_pid = self() |> IO.inspect(label: "cur_pid")
    # IO.inspect(cur_env, label: "cur_env")

    Process.send_after(self(), :render, 16)

    :wx.batch(fn ->
      # spawn(fn -> render(state, cur_pid, cur_env) end)
      # render(state, cur_pid, cur_env)
      case ElixirMetal.MetalRenderer.render_frame(state.renderer) do
        :ok ->
          IO.puts("Rendering frame")

          # send(cur_pid, :ok)
          {:noreply, state}
        {:error, reason} ->
          IO.puts("Failed to render frame: #{inspect(reason)}")
          {:error, reason}
      end
    end)

    # receive do
    #   :ok ->
    #     IO.puts("received")
    #     :wx.set_env(cur_env)
    #   _ -> raise "foo"
    # end

    # :wxWindow.refresh(state.panel)
    # :wxWindow.update(state.panel)

    # {:noreply, state}
  end

  defp render(state, cur_pid, cur_env) do
    IO.inspect(self(), label: "nif")
    IO.inspect(cur_pid, label: "window pid")
    IO.puts("Setting env")
    :wx.set_env(cur_env)
    IO.inspect(:wxWindow.getHandle(state.panel), base: :hex)

    # pu = :wxPopupWindow.new(state.frame)
    # :wxPopupWindow.setForegroundColour(pu, {255, 0, 0})
    # :wxPopupWindow.setBackgroundColour(pu, {0, 255, 0})
    # :wxPopupWindow.show(pu)
    # :wxPopupWindow.raise(pu)

    # IO.inspect(:wx.get_env(), label: "second get_env env")

    case ElixirMetal.MetalRenderer.render_frame(state.renderer) do
      :ok ->
        IO.puts("Rendering frame")

        send(cur_pid, :ok)
      {:error, reason} ->
        IO.puts("Failed to render frame: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
