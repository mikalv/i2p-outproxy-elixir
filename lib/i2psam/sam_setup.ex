defmodule SamSetup do
  require Logger

  @i2cp_opts "inbound.length=1 outbound.length=1 inbound.quantity=5 outbound.quantity=5 inbound.backupQuantity=3 outbound.backupQuantity=3"

  def write_file(filename, private_key) do
    {:ok, file} = File.open(filename, [:write])
    IO.binwrite(file, private_key)
    File.close(file)
  end

  def read_file(filename) do
    {:ok, content} = File.read(filename)
    content
  end

  def read_file(filename, success_fn, failure_fn) do
    case File.read(filename) do
      {:ok, body}      -> success_fn.(body) # do something with the `body`
      {:error, reason} -> failure_fn.(reason) # handle the error caused by `reason`
    end
  end

  def setup_sam_tunnels(hostname \\ "127.0.0.1", port \\ 4480) do
    sampid1 = setup_sam_session()
    # Anti pattern, try to avoid manual sleeps
    :timer.sleep(5000)
    {:ok, sampid2} = SamClient.start_link
    SamClient.start_listen(sampid2, hostname, port)
  end


  defp setup_sam_session() do
    if File.exists?("private_key.txt") do
      {:ok, sampid} = SamClient.start_link
      read_file("private_key.txt",
        fn res ->
          SamClient.create_session(sampid, true, %{
            style: "STREAM",
            destination: res,
            id: "outproxy",
            sig_type: "RedDSA_SHA512_Ed25519",
            i2cp_opts: @i2cp_opts
          })
          Logger.info "Trying to create a session based upon the private key from private_key.txt"
        end,
        fn err -> Logger.error(err) end
      )
      # Always return the sam client pid
      sampid
    else
      {:ok, sampid} = SamClient.start_link
      SamClient.create_session(sampid, true, %{ style: "STREAM", destination: "TRANSIENT", id: "outproxy", sig_type: "RedDSA_SHA512_Ed25519", i2cp_opts: @i2cp_opts })
      :timer.sleep(3000)
      privkey = SamClient.get_private_key(sampid)
      if not is_nil(privkey) do
        write_file("private_key.txt", privkey)
        Logger.info "Wrote private key to the private_key.txt file"
      end
      # Always return the sam client pid
      sampid
    end
  end
end