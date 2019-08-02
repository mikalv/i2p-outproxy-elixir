defmodule SamClient do
  use GenServer
  require Logger

  def send_message(pid, message) do
    GenServer.cast(pid, {:message, message})
  end

  def start_link(opts \\ [sam_host: "127.0.0.1", sam_port: 7656, id: "elixir2", host: "localhost", port: 4480]) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_) do
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
    }
    {:ok, state, {:continue, :connect_sam}}
  end

  def handle_continue(:connect_sam, %{socket: _s} = state) do
    case connect_sam(state) do
      {:ok, socket} -> {:noreply, %{state | socket: socket, ready_for_session: true}}
      {:error, reason} -> Logger.error("Error connecting to I2P SAM: #{reason}")
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

  def handle_info(:send_version_sam, %{socket: socket} = state) do
    send_version(state)
    {:noreply, state}
  end


  def handle_info({:tcp_closed,socket},state) do
    IO.inspect "Socket has been closed"
    {:noreply,state}
  end

  def handle_info({:tcp_error,socket,reason},state) do
    IO.inspect socket,label: "connection closed dut to #{reason}"
    {:noreply,state}
  end

  def disconnect(state, reason) do
    Logger.info "Disconnected: #{reason}"
    {:stop, :normal, state}
  end

  defp send_version(%{socket: socket} = _s) do
    Logger.debug "-> HELLO VERSION"
    write_line("HELLO VERSION\r\n", socket)
  end

  defp remove_session(%{id: id, socket: socket} = _s) do
    write_line("SESSION REMOVE ID=#{id}\r\n", socket)
  end

  def get_private_key(pid), do: GenServer.call(pid, :get_private_key)

  def get_dest_address(pid) do
    dict = :sys.get_state pid
    destination = String.trim(dict[:dest])
  end

  def close(pid), do: GenServer.cast(pid, :close_sam)

  def name_lookup(pid, name \\ "ME"), do: GenServer.cast(pid, {:name_lookup, name})

  def start_listen(pid,server,port) do
    dict = :sys.get_state pid
    if dict[:ready_for_session] == false do
      # Anti pattern, try to avoid manual sleeps
      Logger.info "Ops, too fast, waiting 5 sec"
      :timer.sleep(5000)
    end
    GenServer.cast(pid, {:stream_forward, %{ server_host: server, server_port: port }})
  end

  def create_session(pid, is_server \\ false, %{style: style, id: id, destination: dest, sig_type: sig_type, i2cp_opts: i2cp_opts} = opts \\ %{style: "STREAM", destination: "TRANSIENT", id: "outproxy", sig_type: "RedDSA_SHA512_Ed25519", i2cp_opts: ""}) do
    dict = :sys.get_state pid
    if dict[:ready_for_session] == false do
      Logger.info "Ops, too fast, waiting 5 sec"
      :timer.sleep(5000)
    end
    if is_server do
      GenServer.cast pid, {:create_server_session, opts}
    else
      GenServer.cast pid, {:create_client_session, opts}
    end
  end

  def handle_call(:get_private_key, _from, state) do
    {:reply, String.trim(Map.get(state, :private_key, "")), state}
  end

  def handle_cast({:stream_forward, %{ server_host: host, server_port: port } = msg}, state) do
    host = Map.get(state, :server_host, "127.0.0.1")
    port = Map.get(state, :server_port, "4480")
    id = Map.get(state, :id, "outproxy")
    write_line("STREAM FORWARD ID=#{id} PORT=#{port} HOST=#{host} SILENT=true\r\n", Map.get(state, :socket))
    {:noreply, state}
  end

  def handle_cast(:close_sam, state) do
    if state.remove_session do
      Logger.info "Shutting down session with id #{state.id}"
      remove_session(state)
    end
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

  def handle_cast({:create_client_session, %{style: style, id: id, destination: dest, sig_type: sig_type} = opts}, state) when style=="STREAM" or style=="DATAGRAM" or style=="RAW" do
    handle_create_session(false, opts, state)
  end

  def handle_cast({:create_server_session, %{style: style, id: id, destination: dest, sig_type: sig_type} = opts}, state) when style=="STREAM" or style=="DATAGRAM" or style=="RAW" do
    handle_create_session(true, opts, state)
  end

  def handle_create_session(is_server, %{style: style, id: id, destination: dest, sig_type: sig_type} = opts, state) when style=="STREAM" or style=="DATAGRAM" or style=="RAW" do
    host = Map.get(opts, :host, "127.0.0.1")
    port = Map.get(opts, :port, "4480")
    sig_type = Map.get(opts, :sig_type, "RedDSA_SHA512_Ed25519")
    i2cp_opts = Map.get(opts, :i2cp_opts, "")
    write_line("SESSION CREATE STYLE=#{style} ID=#{id} DESTINATION=#{String.trim(dest)} SIGNATURE_TYPE=#{sig_type} inbound.nickname=#{id} #{i2cp_opts}\r\n", Map.get(state, :socket))
    {:noreply, %{state | id: id, remove_session: true}}
  end

  def handle_info({:tcp, _, "SESSION STATUS RESULT=OK DESTINATION=" <> privkey = fullmsg}, state) do
    Logger.debug "<- #{fullmsg}"
    Logger.info "Destination created, got private key #{privkey}"
    name_lookup(self())
    {:noreply, %{state | private_key: privkey}}
  end

  def handle_info({:tcp, _, "STREAM STATUS RESULT=OK\n" = msg}, state) do
    Logger.debug "<- #{msg}"
    Logger.info "The destination is now bound to the server port"
    {:noreply, state}
  end


  def handle_info({:tcp, _, "STREAM STATUS RESULT=I2P_ERROR" <> _endl = msg}, state) do
    Logger.debug "<- #{msg}"
    Logger.error "Internal i2p error, check router logs"
    {:noreply, state}
  end

  def handle_info({:tcp, _, "STREAM STATUS RESULT=INVALID_ID" <> _endl = msg}, state) do
    Logger.debug "<- #{msg}"
    Logger.warn "Invalid session id"
    {:noreply, state}
  end

  def handle_info({:tcp, _, "SESSION STATUS RESULT=I2P_ERROR MESSAGE=" <> error_msg = fullmsg}, state) do
    Logger.debug "<- #{fullmsg}"
    Logger.error "Sam errored with #{error_msg}"
    Logger.info "Assumes we got disconnected, will reconnect"
    case connect_sam(state) do
      {:ok, socket} -> {:noreply, %{state | socket: socket, ready_for_session: true}}
      {:error, reason} -> Logger.error("Error connecting to I2P SAM: #{reason}")
    end
    {:noreply, %{state | error: error_msg}}
  end
  def handle_info({:tcp, _, "SESSION STATUS RESULT=" <> warn_msg = fullmsg}, state) do
    Logger.debug "<- #{fullmsg}"
    Logger.warn "Sam warning: #{warn_msg}"
    {:noreply, %{state | error: warn_msg}}
  end

  def handle_info({:tcp, _, "HELLO REPLY RESULT=OK VERSION=" <> version = fullmsg}, state) do
    Logger.debug "<- #{fullmsg}"
    Logger.info "Sam version is #{String.trim(version)}"
    {:noreply, %{state | sam_version: String.trim(version)}}
  end

  def handle_info({:tcp, _, "NAMING REPLY RESULT=OK NAME=ME VALUE=" <> own_dest = fullmsg}, state) do
    Logger.debug "<- #{fullmsg}"
    Logger.info "Our destination is: #{own_dest}"
    lookups = Map.merge(state.lookups, %{ME: own_dest})
    state = Map.replace(state, :lookups, lookups)
    {:noreply, %{state | dest: own_dest}}
  end

  def handle_info({:tcp, _, "NAMING REPLY RESULT=OK NAME=" <> hostname_and_rest = fullmsg}, state) do
    Logger.debug "<- #{fullmsg}"
    [hostname, rest] = String.split(hostname_and_rest, " ")
    dest = String.replace_prefix(rest, "VALUE=", "")
    lookups = Map.merge(state.lookups, %{"#{hostname}": dest})
    state = %{state | lookups: lookups}
    Logger.info "State is #{inspect(state)}"
    {:noreply, state}
  end

  def handle_info({:tcp, socket, "PING " <> ping_time}, state) do
    write_line("PONG #{String.trim(ping_time)}\r\n", socket)
    Logger.info "Responded on sam ping message #{ping_time}"
    {:noreply, state}
  end

  def handle_info({:tcp,socket,packet},state) do
    IO.inspect packet, label: "incoming packet"
    Logger.warn "Unhandled incoming packet with content: #{packet}"
    {:noreply,state}
  end

  defp send_and_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command)
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> {:ok, data}
      {:error, :timeout} -> {:error, :timeout}
      {:error, :einval} -> {:error, :einval}
      _ -> {:error, :unknown}
    end
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(line, socket) do
    Logger.debug "-> #{String.trim(line)}"
    :gen_tcp.send(socket, line)
  end
end
