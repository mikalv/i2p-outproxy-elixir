defmodule Sigterm.Sysinfo.FileSystem do

  def lib_dir(app) do
    :code.lib_dir(app)
  end

  def ebin(app) do
    build_ebin = Path.join([lib_dir(app), "ebin"])
    if File.dir?(build_ebin) do
      build_ebin
    else
      Path.join([:code.lib_dir(app), "ebin"])
    end
  end

  def spec(app) do
    try do
      {:ok, application_spec} =
        Path.join([ebin(app), "#{app}.app"])
        |> :file.consult()

      {_, _, application_spec} =
        Enum.find(application_spec, fn
          {:application, ^app, _} -> true
          _ -> false
        end)
      application_spec

    rescue
      _ ->
        Application.load(app)
        Application.spec(app)
    end
  end

  def expand_paths(paths, dir) do
    expand_dir = Path.expand(dir)

    paths
    |> Enum.map(&Path.join(dir, &1))
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.flat_map(&dir_files/1)
    |> Enum.map(&Path.expand/1)
    |> Enum.filter(&File.regular?/1)
    |> Enum.uniq
    |> Enum.map(&Path.relative_to(&1, expand_dir))
  end

  defp dir_files(path) do
    if File.dir?(path) do
      Path.wildcard(Path.join(path, "**"))
    else
      [path]
    end
  end
end
