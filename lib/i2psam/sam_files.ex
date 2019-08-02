defmodule I2psam.SamFiles do

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

end