defmodule JswatchWeb.IndigloManager do
  use GenServer

  def init(ui) do
    :gproc.reg({:p, :l, :ui_event})
    {:ok, %{ui_pid: ui, st: IndigloOff, count: 0, timer1: nil , snooze_timer: nil}}
  end

  def handle_info(:"top-right-pressed", %{ui_pid: pid, st: IndigloOff} = state) do
    GenServer.cast(pid, :set_indiglo)
    {:noreply, %{state | st: IndigloOn}}
  end

  def handle_info(:"top-right-released", %{st: IndigloOn} = state) do
    timer = Process.send_after(self(), Waiting_IndigloOff, 2000)
    {:noreply, %{state | st: Waiting, timer1: timer}}
  end
  def handle_info(:"top-left-pressed", state) do
    :gproc.send({:p, :l, :ui_event}, :update_alarm)
    {:noreply, state}
  end

  def handle_info(:"bottom-right-pressed", %{st: AlarmOn} = state) do
    snooze_timer = Process.send_after(self(), SnoozeActivated, 2000)
    {:noreply, %{state | st: WaitingSnooze, snooze_timer: snooze_timer}}
  end

  def handle_info(:"bottom-right-released", %{st: WaitingSnooze, snooze_timer: snooze_timer} = state) do
    if snooze_timer != nil do
      Process.cancel_timer(snooze_timer)
    end
    GenServer.cast(state.ui_pid, :unset_indiglo)
    {:noreply, %{state | st: AlarmOff, snooze_timer: nil}}
  end

  def handle_info(SnoozeActivated, %{ui_pid: pid, st: WaitingSnooze} = state) do
    IO.puts("El botón inferior derecho fue presionado durante 2 segundos. Snooze activado.")
    GenServer.cast(pid, :unset_indiglo)
    :gproc.send({:p, :l, :ui_event}, :update_alarm)
    {:noreply, %{state | st: IndigloOff}}
  end

  def handle_info(SnoozeActivated, %{ui_pid: pid, st: WaitingSnooze} = state) do
    GenServer.cast(pid, :unset_indiglo)
    :gproc.send({:p, :l, :ui_event}, :update_alarm)
    {:noreply, %{state | st: IndigloOff}}
  end

  def handle_info(:start_alarm, %{ui_pid: pid, st: IndigloOff} = state) do
    Process.send_after(self(), AlarmOn_AlarmOff, 500)
    GenServer.cast(pid, :set_indiglo)
    {:noreply, %{state | count: 51, st: AlarmOn}}
  end

  def handle_info(:start_alarm, %{st: IndigloOn} = state) do
    Process.send_after(self(), AlarmOff_AlarmOn, 500)
    {:noreply, %{state | count: 51, st: AlarmOff}}
  end

  def handle_info(Waiting_IndigloOff, %{ui_pid: pid, st: Waiting, timer1: timer} = state) do
    if timer != nil do
      Process.cancel_timer(timer)
    end
    GenServer.cast(pid, :unset_indiglo)
    Process.send_after(self(), AlarmOff_AlarmOn, 500)

    {:noreply, %{state| count: 51, timer1: nil, st: AlarmOff}}
  end


  def handle_info(AlarmOn_AlarmOff, %{ui_pid: pid, count: count, st: AlarmOn} = state) do
    if count >= 1 do
      Process.send_after(self(), AlarmOff_AlarmOn, 500)
      GenServer.cast(pid, :unset_indiglo)
      {:noreply, %{state | count: count - 1, st: AlarmOff}}
    else
      GenServer.cast(pid, :unset_indiglo)
      {:noreply, %{state | count: 0, st: IndigloOff}}
    end
  end

  def handle_info(AlarmOff_AlarmOn, %{ui_pid: pid, count: count, st: AlarmOff} = state) do
    if count >= 1 do
      Process.send_after(self(), AlarmOn_AlarmOff, 500)
      GenServer.cast(pid, :set_indiglo)
      {:noreply, %{state | count: count - 1, st: AlarmOn}}
    else
      GenServer.cast(pid, :unset_indiglo)
      {:noreply, %{state | count: 0, st: IndigloOff}}
    end
  end

  def handle_info(event, state) do
    IO.inspect(event)
    {:noreply, state}
  end
end
