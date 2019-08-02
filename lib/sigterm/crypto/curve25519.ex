defmodule Sigterm.Crypto.Curve25519 do
  import Bitwise

  @moduledoc """
  Curve25519 Diffie-Hellman functions
  """
  @typedoc """
  public or secret key
  """
  @type key :: binary

  @p 57_896_044_618_658_097_711_785_492_504_343_953_926_634_992_332_820_282_019_728_792_003_956_564_819_949
  @a 486_662

  defp clamp(c) do
    c
    |> band(~~~7)
    |> band(~~~(128 <<< (8 * 31)))
    |> bor(64 <<< (8 * 31))
  end

  # :math.pow yields floats.. and we only need this one
  defp square(x), do: x * x

  defp expmod(_b, 0, _m), do: 1

  defp expmod(b, e, m) do
    t = b |> expmod(div(e, 2), m) |> square |> rem(m)
    if (e &&& 1) == 1, do: rem(t * b, m), else: t
  end

  defp inv(x), do: x |> expmod(@p - 2, @p)

  defp add({xn, zn}, {xm, zm}, {xd, zd}) do
    x = (xm * xn - zm * zn) |> square |> (&(&1 * 4 * zd)).()
    z = (xm * zn - zm * xn) |> square |> (&(&1 * 4 * xd)).()
    {rem(x, @p), rem(z, @p)}
  end

  defp double({xn, zn}) do
    x = (square(xn) - square(zn)) |> square
    z = 4 * xn * zn * (square(xn) + @a * xn * zn + square(zn))
    {rem(x, @p), rem(z, @p)}
  end

  defp curve25519(n, base) do
    one = {base, 1}
    two = double(one)
    {{x, z}, _} = nth_mult(n, {one, two})
    rem(x * inv(z), @p)
  end

  defp nth_mult(1, basepair), do: basepair

  defp nth_mult(n, {one, two}) do
    {pm, pm1} = n |> div(2) |> nth_mult({one, two})
    if (n &&& 1) == 1, do: {add(pm, pm1, one), double(pm1)}, else: {double(pm), add(pm, pm1, one)}
  end

  @doc """
  Generate a secret/public key pair
  Returned tuple contains `{random_secret_key, derived_public_key}`
  """
  @spec generate_key_pair :: {key, key}
  def generate_key_pair do
    # This algorithm is supposed to be resilient against poor RNG, but use the best we can
    secret = :crypto.strong_rand_bytes(32)
    {secret, derive_public_key(secret)}
  end

  @doc """
  Derive a shared secret for a secret and public key
  Given our secret key and our partner's public key, returns a
  shared secret which can be derived by the partner in a complementary way.
  """
  @spec derive_shared_secret(key, key) :: key | :error
  def derive_shared_secret(<<our_secret::little-size(256)>>, <<their_public::little-size(256)>>) do
    shared_secret =
      our_secret
      |> clamp
      |> curve25519(their_public)

    <<shared_secret::little-size(256)>>
  end

  def derive_shared_secret(_ours, _theirs), do: :error

  @doc """
  Derive the public key from a secret key
  """
  @spec derive_public_key(key) :: key | :error
  def derive_public_key(<<our_secret::little-size(256)>>) do
    public_key =
      our_secret
      |> clamp
      |> curve25519(9)

    <<public_key::little-size(256)>>
  end

  def derive_public_key(_ours), do: :error
end
