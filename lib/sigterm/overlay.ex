defmodule Sigterm.Overlay do
  alias Sigterm.Utils

  defstruct [hash: nil, delta: []]

  @type t :: %__MODULE__{
    hash: String.t,
    delta: [Sigterm.Application.t]
  }

  def load(sources, targets) when is_list(sources) and is_list(targets) do
    delta = Sigterm.Application.compare(sources, targets)
    %__MODULE__{
      delta: delta
    }
  end
  def load(source, target), do: load([source], [target])

  def apply(%__MODULE__{} = overlay, overlay_dir) do
    overlay_path = Path.join(overlay_dir, hash(overlay.delta))
    Enum.each(overlay.delta, &Sigterm.Application.apply(&1, overlay_path))
  end

  def hash(applications) do
      applications
      |> Enum.map(fn({_, app}) -> app end)
      |> Enum.map(& &1.hash)
      |> Enum.join
      |> Utils.hash
  end

end
