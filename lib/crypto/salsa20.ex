defmodule Salsa20 do
  @moduledoc """
  Salsa20 symmetric stream cipher
  As specified in http://cr.yp.to/snuffle/spec.pdf.
  Also includes the HSalsa20 hashing function as specified in
  http://cr.yp.to/highspeed/naclcrypto-20090310.pdf
  """
  import Bitwise

  defp rotl(x, r), do: rem(x <<< r ||| x >>> (32 - r), 0x100000000)
  defp sum(x, y), do: rem(x + y, 0x100000000)

  @typedoc """
  The shared encryption key.
  32-byte values are to be preferred over 16-byte ones where possible.
  """
  @type key :: binary
  @typedoc """
  The shared per-session nonce.
  By spec, this nonce may be used to encrypt a stream of up to 2^70 bytes.
  """
  @type nonce :: binary
  @typedoc """
  The parameters and state of the current session
  * The shared key
  * The session nonce
  * The next block number
  * The unused portion of the current block
  Starting from block 0 the initial state is `{k,v,0,""}`
  """
  @type salsa_parameters :: {key, nonce, non_neg_integer, binary}

  # Many functions below are public but undocumented.
  # This is to allow for testing vs the spec, without confusing consumers.
  @doc false
  def quarterround([y0, y1, y2, y3]) do
    z1 = y1 ^^^ rotl(sum(y0, y3), 7)
    z2 = y2 ^^^ rotl(sum(z1, y0), 9)
    z3 = y3 ^^^ rotl(sum(z2, z1), 13)
    z0 = y0 ^^^ rotl(sum(z3, z2), 18)

    [z0, z1, z2, z3]
  end

  @doc false
  def rowround([y0, y1, y2, y3, y4, y5, y6, y7, y8, y9, y10, y11, y12, y13, y14, y15]) do
    [z0, z1, z2, z3] = quarterround([y0, y1, y2, y3])
    [z5, z6, z7, z4] = quarterround([y5, y6, y7, y4])
    [z10, z11, z8, z9] = quarterround([y10, y11, y8, y9])
    [z15, z12, z13, z14] = quarterround([y15, y12, y13, y14])

    [z0, z1, z2, z3, z4, z5, z6, z7, z8, z9, z10, z11, z12, z13, z14, z15]
  end

  @doc false
  def columnround([x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15]) do
    [y0, y4, y8, y12] = quarterround([x0, x4, x8, x12])
    [y5, y9, y13, y1] = quarterround([x5, x9, x13, x1])
    [y10, y14, y2, y6] = quarterround([x10, x14, x2, x6])
    [y15, y3, y7, y11] = quarterround([x15, x3, x7, x11])

    [y0, y1, y2, y3, y4, y5, y6, y7, y8, y9, y10, y11, y12, y13, y14, y15]
  end

  @doc false
  def doubleround(x), do: x |> columnround |> rowround

  @doc false
  def doublerounds(x, 0), do: x
  def doublerounds(x, n), do: x |> doubleround |> doublerounds(n - 1)

  @doc false
  def littleendian_inv(i), do: i |> :binary.encode_unsigned(:little) |> pad(4)
  defp pad(s, n) when s |> byte_size |> rem(n) == 0, do: s
  defp pad(s, n), do: pad(s <> <<0>>, n)

  @doc """
  HSalsa20 hash
  The strict specification requires a 32-byte key, but the defined
  expansion function can be used with a 16-byte key.
  """
  @spec hash(key, nonce) :: binary
  def hash(k, n) do
    k
    |> expand(n)
    |> words_as_ints([])
    |> doublerounds(10)
    |> pick_elements
    |> Enum.join()
  end

  defp pick_elements(zs) do
    zt = zs |> List.to_tuple()
    [0, 5, 10, 15, 6, 7, 8, 9] |> Enum.map(fn n -> littleendian_inv(elem(zt, n)) end)
  end

  @doc false
  def s20_hash(b, rounds \\ 1) when is_binary(b) and byte_size(b) == 64,
    do: b |> words_as_ints([]) |> s20_hash_rounds(rounds)

  defp s20_hash_rounds(xs, 0), do: xs |> Enum.map(&littleendian_inv/1) |> Enum.join()

  defp s20_hash_rounds(xs, n) do
    xs
    |> doublerounds(10)
    |> Enum.zip(xs)
    |> Enum.map(fn {z, x} -> sum(x, z) end)
    |> s20_hash_rounds(n - 1)
  end

  defp words_as_ints(<<>>, acc), do: acc |> Enum.reverse()

  defp words_as_ints(<<word::unsigned-little-integer-size(32), rest::binary>>, acc),
    do: words_as_ints(rest, [word | acc])

  @doc false
  def expand(k, n) when byte_size(k) == 16 and byte_size(n) == 16 do
    t0 = <<101, 120, 112, 97>>
    t1 = <<110, 100, 32, 49>>
    t2 = <<54, 45, 98, 121>>
    t3 = <<116, 101, 32, 107>>

    t0 <> k <> t1 <> n <> t2 <> k <> t3
  end

  def expand(k, n) when byte_size(k) == 32 and byte_size(n) == 16 do
    {k0, k1} = {binary_part(k, 0, 16), binary_part(k, 16, 16)}
    s0 = <<101, 120, 112, 97>>
    s1 = <<110, 100, 32, 51>>
    s2 = <<50, 45, 98, 121>>
    s3 = <<116, 101, 32, 107>>

    s0 <> k0 <> s1 <> n <> s2 <> k1 <> s3
  end

  @doc """
  The crypt function suitable for a complete message.
  This is a convenience wrapper when the full message is ready for processing.
  The operations are symmetric, so if `crypt(m,k,v) = c`, then `crypt(c,k,v) = m`
  """

  @spec crypt(binary, key, nonce, non_neg_integer) :: binary
  def crypt(m, k, v, b \\ 0) do
    {s, _p} = crypt_bytes(m, {k, v, b, ""}, [])
    s
  end

  @doc """
  The crypt function suitable for streaming
  Use an initial state of `{k,v,0,""}`
  The returned parameters can be used for the next available bytes.
  Any previous emitted binary can be included in the `acc`, if desired.
  """

  @spec crypt_bytes(binary, salsa_parameters, [binary]) :: {binary, salsa_parameters}
  def crypt_bytes(<<>>, p, acc), do: {acc |> Enum.reverse() |> Enum.join(), p}
  def crypt_bytes(m, {k, v, n, <<>>}, acc), do: crypt_bytes(m, {k, v, n + 1, block(k, v, n)}, acc)

  def crypt_bytes(<<m, restm::binary>>, {k, v, n, <<b, restb::binary>>}, acc),
    do: crypt_bytes(restm, {k, v, n, restb}, [<<bxor(m, b)>> | acc])

  defp block(k, v, n) do
    c = n |> :binary.encode_unsigned() |> pad(8) |> binary_part(0, 8)
    k |> expand(v <> c) |> s20_hash
  end
end
