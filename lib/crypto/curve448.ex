defmodule Curve448 do
  import Bitwise

  @moduledoc """
  Curve448 Diffie-Hellman functions
  """
  @typedoc """
  public or secret key
  """
  @type key :: <<_::224>>

  @p 726_838_724_295_606_890_549_323_807_888_004_534_353_641_360_687_318_060_281_490_199_180_612_328_166_730_772_686_396_383_698_676_545_930_088_884_461_843_637_361_053_498_018_365_439
  @a 156_326

  defp clamp(c) do
    c |> band(~~~3)
    |> bor(128 <<< (8 * 55))
  end

  # :math.pow yields floats.. and we only need this one
  defp square(x), do: x * x

  defp expmod(_b, 0, _m), do: 1

  defp expmod(b, e, m) do
    t = b |> expmod(div(e, 2), m) |> square |> rem(m)

    case e &&& 1 do
      1 -> rem(t * b, m)
      _ -> t
    end
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

  def curve448(n, base) do
    one = {base, 1}
    two = double(one)
    {{x, z}, _} = nth_mult(n, {one, two})
    rem(x * inv(z), @p)
  end

  defp nth_mult(1, basepair), do: basepair

  defp nth_mult(n, {one, two}) do
    {pm, pm1} = n |> div(2) |> nth_mult({one, two})

    case n &&& 1 do
      1 -> {add(pm, pm1, one), double(pm1)}
      _ -> {double(pm), add(pm, pm1, one)}
    end
  end

  @doc """
  Generate a secret/public key pair
  Returned tuple contains `{random_secret_key, derived_public_key}`
  """
  @spec generate_key_pair :: {key, key}
  def generate_key_pair do
    # This algorithm is supposed to be resilient against poor RNG, but use the best we can
    secret = :crypto.strong_rand_bytes(56)
    {secret, derive_public_key(secret)}
  end

  @doc """
  Derive a shared secret for a secret and public key
  Given our secret key and our partner's public key, returns a
  shared secret which can be derived by the partner in a complementary way.
  """
  @spec derive_shared_secret(key, key) :: key | :error
  def derive_shared_secret(<<our_secret::little-size(448)>>, <<their_public::little-size(448)>>) do
    shared_secret =
      our_secret
      |> clamp
      |> curve448(their_public)

    <<shared_secret::little-size(448)>>
  end

  def derive_shared_secret(_ours, _theirs), do: :error

  @doc """
  Derive the public key from a secret key
  """
  @spec derive_public_key(key) :: key | :error
  def derive_public_key(<<our_secret::little-size(448)>>) do
    public_key =
      our_secret
      |> clamp
      |> curve448(5)

    <<public_key::little-size(448)>>
  end

  def derive_public_key(_ours), do: :error
end
