defmodule Sigterm.Crypto.Chacha20 do
  @moduledoc """
  Chacha20 symmetric stream cipher
  https://tools.ietf.org/html/rfc7539
  The calling semantics are still sub-optimal and no performance tuning has been done.
  """
  import Bitwise

  defp rotl(x, r), do: rem(x <<< r ||| x >>> (32 - r), 0x100000000)
  defp sum(x, y), do: rem(x + y, 0x100000000)

  @typedoc """
  The shared encryption key.
  """
  @type key :: binary
  @typedoc """
  The shared per-session nonce.
  By spec, this nonce may be used to encrypt a stream of up to 256GiB
  An eight-byte nonce is compatible with the original reference implementation.
  """
  @type nonce :: binary
  @typedoc """
  The parameters and state of the current session
  * The shared key
  * The session nonce
  * The next block number
  * The unused portion of the current block
  To start from block 0, the initial state is `{k,n,0,""}`
  """
  @type chacha_parameters :: {key, nonce, non_neg_integer, binary}

  # Many functions below are public but undocumented.
  # This is to allow for testing vs the spec, without confusing consumers.
  @doc false
  def quarterround([a, b, c, d]) do
    a = sum(a, b)
    d = rotl(d ^^^ a, 16)
    c = sum(c, d)
    b = rotl(b ^^^ c, 12)
    a = sum(a, b)
    d = rotl(d ^^^ a, 8)
    c = sum(c, d)
    b = rotl(b ^^^ c, 7)

    [a, b, c, d]
  end

  @doc false
  def diaground([y0, y1, y2, y3, y4, y5, y6, y7, y8, y9, y10, y11, y12, y13, y14, y15]) do
    [z0, z5, z10, z15] = quarterround([y0, y5, y10, y15])
    [z1, z6, z11, z12] = quarterround([y1, y6, y11, y12])
    [z2, z7, z8, z13] = quarterround([y2, y7, y8, y13])
    [z3, z4, z9, z14] = quarterround([y3, y4, y9, y14])

    [z0, z1, z2, z3, z4, z5, z6, z7, z8, z9, z10, z11, z12, z13, z14, z15]
  end

  @doc false
  def columnround([x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15]) do
    [y0, y4, y8, y12] = quarterround([x0, x4, x8, x12])
    [y1, y5, y9, y13] = quarterround([x1, x5, x9, x13])
    [y2, y6, y10, y14] = quarterround([x2, x6, x10, x14])
    [y3, y7, y11, y15] = quarterround([x3, x7, x11, x15])

    [y0, y1, y2, y3, y4, y5, y6, y7, y8, y9, y10, y11, y12, y13, y14, y15]
  end

  @doc false
  def doubleround(x), do: x |> columnround |> diaground

  @doc false
  def doublerounds(x, 0), do: x
  def doublerounds(x, n), do: x |> doubleround |> doublerounds(n - 1)

  @doc false
  def littleendian_inv(i), do: i |> :binary.encode_unsigned(:little) |> pad(4)
  defp pad(s, n) when rem(byte_size(s), n) == 0, do: s
  defp pad(s, n), do: pad(s <> <<0>>, n)

  @doc """
  Return an arbitrary block
  This is probably most useful in fast-forwarding a stream.
  """
  @spec block(key, nonce, non_neg_integer) :: binary
  def block(k, n, b) when byte_size(k) == 32 do
    xs = expand(k, n, b)

    xs |> doublerounds(10) |> Enum.zip(xs)
    |> Enum.reduce(<<>>, fn {z, x}, acc -> acc <> littleendian_inv(sum(x, z)) end)
  end

  defp words_as_ints(<<>>, acc), do: acc |> Enum.reverse()

  defp words_as_ints(<<word::unsigned-little-integer-size(32), rest::binary>>, acc),
    do: words_as_ints(rest, [word | acc])

  @doc false
  def expand(k, n, b) when byte_size(n) == 12 do
    cs = "expand 32-byte k"

    words_as_ints(cs <> k <> littleendian_inv(b) <> n, [])
  end

  def expand(k, n, b) when byte_size(n) == 8, do: expand(k, <<0, 0, 0, 0>> <> n, b)

  @doc """
  The crypt function suitable for a complete message.
  This is a convenience wrapper when the full message is ready for processing.
  The operations are symmetric, so if `crypt(m,k,n) = c`, then `crypt(c,k,n) = m`
  """

  @spec crypt(binary, key, nonce, non_neg_integer) :: binary
  def crypt(m, k, n, c \\ 0) do
    {s, _p} = crypt_bytes(m, {k, n, c, ""}, [])
    s
  end

  @doc """
  The crypt function suitable for streaming
  Use an initial state of `{k,n,0,""}`
  The returned parameters can be used for the next available bytes.
  Any previous emitted binary can be included in the `acc`, if desired.
  """

  @spec crypt_bytes(binary, chacha_parameters, [binary]) :: {binary, chacha_parameters}
  def crypt_bytes(<<>>, p, acc), do: {acc |> Enum.reverse() |> Enum.join(), p}
  def crypt_bytes(m, {k, n, u, <<>>}, acc), do: crypt_bytes(m, {k, n, u + 1, block(k, n, u)}, acc)

  def crypt_bytes(<<m, restm::binary>>, {k, n, u, <<b, restb::binary>>}, acc),
    do: crypt_bytes(restm, {k, n, u, restb}, [<<bxor(m, b)>> | acc])
end
