defmodule I2psam.SamSetup do
  require Logger

  @tunnelID Application.get_env :i2psam, :tunnelID
  @tunnelSignatureType Application.get_env :i2psam, :signatureType
  @tunnelLength Application.get_env :i2psam, :tunnelLength
  @tunnelQuantity Application.get_env :i2psam, :tunnelQuantity
  @tunnelBackupQuantity Application.get_env :i2psam, :tunnelBackupQuantity

  @i2cp_opts "inbound.length=#{@tunnelLength} outbound.length=#{@tunnelLength} inbound.quantity=#{@tunnelQuantity} outbound.quantity=#{@tunnelQuantity} inbound.backupQuantity=#{@tunnelBackupQuantity} outbound.backupQuantity=#{@tunnelBackupQuantity}"

  def bootstrap(hostname \\ "127.0.0.1", port \\ 4480, conf_path \\ "/tmp") do
    setup_sam_tunnels(hostname, port, conf_path)
  end

  defp setup_sam_tunnels(hostname, port, conf_path) do
    Logger.info "Setting up I2P SAM tunnels"
    # Create a socket and start a session
    sampid1 = setup_sam_session(Path.join(conf_path, "http-proxy-private_key.txt"))
    # Create a second socket and stream foward the traffic to a local ip:port
    sampid2 = setup_sam_tunnel_forwarding(sampid1, hostname, port)
    # Close the first socket
    #SamClient.close sampid1
    {:ok, sampid1, sampid2}
  end

  defp reset_sam_tunnels(sampid1, sampid2, hostname, port, conf_path) when is_pid(sampid1) and is_pid(sampid2) do
    Process.exit(sampid1, :kill)
    Process.exit(sampid2, :kill)
    Logger.info "Killed old I2P SAM actors/processes"
    setup_sam_tunnels(hostname, port, conf_path)
  end

  # This function sets up the forwarding to the local ip:port endpoint.
  # The function will loop until a sam session is available.
  defp setup_sam_tunnel_forwarding(sampid1, hostname, port) do
    ds = :sys.get_state(sampid1)
    session_exists = ds[:session_created]
    if not session_exists do
      # Anti pattern, try to avoid manual sleeps
      :timer.sleep(5000)
      # Call itself until session is ready
      setup_sam_tunnel_forwarding(sampid1, hostname, port)
    else
      # Spawn connection number two to the sam control port,
      # this time to issue stream forwarding for our service.
      {:ok, sampid2} = I2psam.SamClient.start_link
      I2psam.SamClient.start_listen(sampid2, sampid1, hostname, port)
      sampid2
    end
  end

  defp extract_private_key(sampid, privkey_filename) when is_pid(sampid) do
    privkey = I2psam.SamClient.get_private_key(sampid)
    if is_nil(privkey) do
      :timer.sleep(3000)
      # Looping until available
      extract_private_key(sampid, privkey_filename)
    else
      I2psam.SamFiles.write_file(privkey_filename, privkey)
      Logger.info "Wrote private key to the private_key.txt file"
    end
  end

  def setup_sam_session(privkey_filename \\ "private_key.txt") do
    if File.exists?(privkey_filename) do
      {:ok, sampid} = I2psam.SamClient.start_link
      I2psam.SamFiles.read_file(privkey_filename,
        fn res ->
          I2psam.SamClient.create_session(sampid, true, %{
            style: "STREAM",
            destination: res,
            id: @tunnelID,
            sig_type: @tunnelSignatureType,
            i2cp_opts: @i2cp_opts
          })
          Logger.info "Trying to create a session from the private key found in #{privkey_filename}"
        end,
        fn err -> Logger.error(err) end
      )
      # Always return the sam client pid
      sampid
    else
      {:ok, sampid} = I2psam.SamClient.start_link
      I2psam.SamClient.create_session(sampid, true, %{
        style: "STREAM",
        destination: "TRANSIENT",
        id: @tunnelID,
        sig_type: @tunnelSignatureType,
        i2cp_opts: @i2cp_opts
      })
      extract_private_key(sampid, privkey_filename)
      # Always return the sam client pid
      sampid
    end
  end
end