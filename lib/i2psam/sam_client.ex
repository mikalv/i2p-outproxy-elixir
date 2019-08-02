defmodule I2psam.SamClient do
  use GenServer
  require Logger

  def send_message(pid, message) do
    GenServer.cast(pid, {:message, message})
  end

  def start_link(opts \\ [sam_host: "127.0.0.1", sam_port: 7656, id: "elixir2", host: "localhost", port: 4480]) do
    GenServer.start_link(__MODULE__, opts, []) # {:name,"#{__MODULE__}#{System.unique_integer}"}
  end

  def init(opts) do
    Logger.info "Options: #{inspect(opts)}"
    state = %{
      socket: nil,
      error: nil,
      dest: nil,
      sam_version: nil,
      private_key: nil,
      id: "outproxy",
      remove_session: false,
      lookups: Map.new,
      ready_for_session: false,
      session_created: false,
    }
    {:ok, state, {:continue, :connect_sam}}
  end

  def handle_continue(:connect_sam, %{socket: _s} = state) do
    Logger.info "Connecting to I2P SAM"
    case connect_sam(state) do
      {:ok, socket} ->
        {:noreply, %{state | socket: socket, ready_for_session: true}}
      {:error, reason} ->
        Logger.error("Error connecting to I2P SAM: #{reason}")
        {:noreply, state}
    end
  end

  defp connect_sam(state) do
    opts = [:binary, packet: :line, active: true, keepalive: true]
    case :gen_tcp.connect('127.0.0.1', 7656, opts) do
      {:ok, socket} ->
        Logger.info "Socket connected"
        send(self(), :send_version_sam)
        {:ok, socket}
      {:error, reason} ->
        disconnect(state, reason)
        {:error, reason}
    end
  end

  def handle_info(:send_version_sam, %{socket: _s} = state) do
    send_version(state)
    {:noreply, state}
  end


  def handle_info({:tcp_closed, _s},state) do
    IO.inspect "Socket has been closed"
    {:noreply, state}
  end

  def handle_info({:tcp_error, socket, reason}, state) do
    IO.inspect socket, label: "connection closed dut to #{reason}"
    {:noreply, state}
  end

  def disconnect(state, reason) do
    Logger.info "Disconnected: #{reason}"
    {:stop, :normal, state}
  end

  defp send_version(%{socket: socket} = _s) do
    write_line("HELLO VERSION MIN=3.1 MAX=3.1\r\n", socket)
  end

  #defp remove_session(%{id: id, socket: socket} = _s) do
  #  write_line("SESSION REMOVE ID=#{id}\r\n", socket)
  #end

  def get_private_key(pid), do: GenServer.call(pid, :get_private_key)

  def get_dest_address(pid) do
    dict = :sys.get_state pid
    destination = String.trim(dict[:dest])
    destination
  end

  def close(pid), do: GenServer.cast(pid, :close_sam)

  def name_lookup(pid, name \\ "ME"), do: GenServer.cast(pid, {:name_lookup, name})

  def start_listen(pid, parent_sam_pid, server \\ "127.0.0.1", port \\ 4480) when is_pid(pid) and is_pid(parent_sam_pid) do
    dict = :sys.get_state parent_sam_pid
    id = dict[:id]
    if dict[:ready_for_session] == false do
      # Anti pattern, try to avoid manual sleeps
      Logger.info "Ops, too fast, waiting 5 sec"
      :timer.sleep(5000)
      # Loop until all ok
      start_listen(pid, parent_sam_pid, server, port)
    else
      # We must wait until after version handshake.
      # Therefore check our own pid state to determe if it's done or not.
      dict = :sys.get_state pid
      if is_nil(dict[:sam_version]) do
        # Anti pattern, try to avoid manual sleeps
        Logger.info "Ops, too fast, waiting 5 sec"
        :timer.sleep(5000)
        # Loop until all ok
        start_listen(pid, parent_sam_pid, server, port)
      else
        GenServer.cast(pid, {:stream_forward, %{ id: id, server_host: server, server_port: port }})
      end
    end
  end

  def create_session(pid, is_server \\ false, %{style: _s, id: _id, destination: _d, sig_type: _st, i2cp_opts: _i2} = opts \\ %{style: "STREAM", destination: "TRANSIENT", id: "outproxy", sig_type: "RedDSA_SHA512_Ed25519", i2cp_opts: ""}) when is_pid(pid) do
    dict = :sys.get_state pid
    if dict[:ready_for_session] == false do
      Logger.info "Ops, too fast, waiting 5 sec"
      :timer.sleep(5000)
      # Loop until all ok
      create_session(pid, is_server, opts)
    else
      if is_server do
        GenServer.cast pid, {:create_server_session, opts}
      else
        GenServer.cast pid, {:create_client_session, opts}
      end
    end
  end

  def handle_info(:kill, %{} = _msg, state) do
    Logger.info "Bye cruel world!"
    {:noreply, state}
  end

  def handle_call(:get_private_key, _from, state) do
    {:reply, String.trim(Map.get(state, :private_key, "")), state}
  end

  def handle_cast({:stream_forward, %{ id: id, server_host: host, server_port: port } = _msg}, state) do
    write_line("STREAM FORWARD ID=#{id} PORT=#{port} HOST=#{host} SILENT=true\r\n", Map.get(state, :socket))
    {:noreply, state}
  end

  def handle_cast(:close_sam, state) do
    #if state.remove_session do
    #  Logger.info "Shutting down session with id #{state.id}"
    #  remove_session(state)
    #end
    write_line("EXIT\r\n", state.socket)
    {:noreply, %{state | id: nil, remove_session: false}}
  end

  def handle_cast({:name_lookup, "ME" = name}, state) do
    if is_nil(state.dest) do
      write_line("NAMING LOOKUP NAME=#{String.trim(name)}\r\n", state.socket)
      Logger.info "Looking up #{name}"
      {:noreply, state}
    else
      Logger.info "We already know ourself, which is #{state.dest}"
      {:noreply, state}
    end
  end

  def handle_cast({:name_lookup, name}, state) do
    write_line("NAMING LOOKUP NAME=#{String.trim(name)}\r\n", state.socket)
    Logger.info "Looking up #{name}"
    {:noreply, state}
  end

  def handle_cast({:create_client_session, %{style: style} = opts}, state) when style=="STREAM" or style=="DATAGRAM" or style=="RAW" do
    handle_create_session(opts, state)
  end

  def handle_cast({:create_server_session, %{style: style} = opts}, state) when style=="STREAM" or style=="DATAGRAM" or style=="RAW" do
    handle_create_session(opts, state)
  end

  def handle_create_session(%{style: style, id: id, destination: dest, sig_type: _st} = opts, state) when style=="STREAM" or style=="DATAGRAM" or style=="RAW" do
    sig_type = Map.get(opts, :sig_type, "RedDSA_SHA512_Ed25519")
    i2cp_opts = Map.get(opts, :i2cp_opts, "")
    write_line("SESSION CREATE STYLE=#{style} ID=#{id} DESTINATION=#{String.trim(dest)} SIGNATURE_TYPE=#{sig_type} inbound.nickname=#{id} #{i2cp_opts}\r\n", Map.get(state, :socket))
    {:noreply, %{state | id: id, remove_session: true}}
  end

  def handle_info({:tcp, _, "EXIT STATUS RESULT=OK MESSAGE=bye" = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    Logger.info "Closed connection with I2P SAM successfully"
    {:noreply, state}
  end

  def handle_info({:tcp, _, "EXIT STATUS RESULT=OK MESSAGE=" <> qmsg = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    Logger.info "Closed connection with SAM response: #{qmsg}"
    {:noreply, state}
  end

  def handle_info({:tcp, _, "SESSION STATUS RESULT=OK DESTINATION=" <> privkey = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    Logger.info "Destination created, got private key #{privkey}"
    name_lookup(self())
    {:noreply, %{state | private_key: privkey, session_created: true}}
  end

  def handle_info({:tcp, _, "STREAM STATUS RESULT=OK\n" = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    Logger.info "The destination is now bound to the server port"
    {:noreply, state}
  end

  def handle_info({:tcp, _, "STREAM STATUS RESULT=I2P_ERROR" <> _endl = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    Logger.error "Internal i2p error, check router logs"
    {:noreply, state}
  end

  def handle_info({:tcp, _, "STREAM STATUS RESULT=INVALID_ID" <> _endl = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    Logger.warn "Invalid session id"
    {:noreply, state}
  end

  def handle_info({:tcp, _, "SESSION STATUS RESULT=I2P_ERROR MESSAGE=" <> error_msg = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    Logger.error "Sam errored with #{error_msg}"
    Logger.info "Assumes we got disconnected, will reconnect"
    case connect_sam(state) do
      {:ok, socket} -> {:noreply, %{state | socket: socket, ready_for_session: true}}
      {:error, reason} -> Logger.error("Error connecting to I2P SAM: #{reason}")
    end
    {:noreply, %{state | error: error_msg}}
  end

  def handle_info({:tcp, _, "SESSION STATUS RESULT=" <> warn_msg = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    Logger.warn "Sam warning: #{warn_msg}"
    {:noreply, %{state | error: warn_msg}}
  end

  def handle_info({:tcp, _, "HELLO REPLY RESULT=OK VERSION=" <> version = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    Logger.info "Sam version is #{String.trim(version)}"
    {:noreply, %{state | sam_version: String.trim(version)}}
  end

  def handle_info({:tcp, _, "NAMING REPLY RESULT=OK NAME=ME VALUE=" <> own_dest = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    Logger.info "Our destination is: #{own_dest}"
    lookups = Map.merge(state.lookups, %{ME: own_dest})
    state = Map.put(state, :lookups, lookups)
    {:noreply, %{state | dest: own_dest}}
  end

  def handle_info({:tcp, _, "NAMING REPLY RESULT=OK NAME=" <> hostname_and_rest = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    [hostname, rest] = String.split(hostname_and_rest, " ")
    dest = String.replace_prefix(rest, "VALUE=", "")
    lookups = Map.merge(state.lookups, %{"#{hostname}": dest})
    state = %{state | lookups: lookups}
    Logger.info "State is #{inspect(state)}"
    {:noreply, state}
  end

  def handle_info({:tcp, socket, "PING " <> ping_time = fullmsg}, state) do
    Logger.debug "(#{inspect(self())}) <- #{String.trim(fullmsg)}"
    write_line("PONG #{String.trim(ping_time)}\r\n", socket)
    Logger.info "Responded on sam ping message #{ping_time}"
    {:noreply, state}
  end

  def handle_info({:tcp, _socket, packet}, state) do
    IO.inspect packet, label: "incoming packet"
    Logger.warn "Unhandled incoming packet with content: #{packet}"
    {:noreply, state}
  end

  def handle_info({:EXIT, from, reason}, state) do
    Logger.info "Exit pid: #{inspect from} reason: #{inspect reason}"
    {:noreply, state}
  end

  #defp send_and_recv(socket, command) do
  #  :ok = :gen_tcp.send(socket, command)
  #  case :gen_tcp.recv(socket, 0) do
  #    {:ok, data} -> {:ok, data}
  #    {:error, :timeout} -> {:error, :timeout}
  #    {:error, :einval} -> {:error, :einval}
  #    _ -> {:error, :unknown}
  #  end
  #end

  #defp read_line(socket) do
  #  {:ok, data} = :gen_tcp.recv(socket, 0)
  #  data
  #end

  defp write_line(line, socket) do
    Logger.debug "(#{inspect(self())}) -> #{String.trim(line)}"
    :gen_tcp.send(socket, line)
  end
end
