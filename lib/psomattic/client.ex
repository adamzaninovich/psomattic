defmodule Psomattic.Client do
  @moduledoc """
  Makes HTTP requests, supports compression
  """

  def make_request!(url) do
    headers = [
      {"Accept", "text/html"},
      {"Accept-Encoding", "gzip, deflate, identity"},
      {"Accept-language", "en-US,en"},
      {"User-Agent", "Mozilla/5.0"}
    ]

    request = %HTTPoison.Request{
      method: :get,
      url: url,
      headers: headers
    }

    with {:ok, response} <- HTTPoison.request(request) do
      decode_body(response)
    else
      other -> raise("HTTP Error: #{inspect(other)}")
    end
  end

  defp decode_body(%{headers: headers, body: encoded_body}) do
    headers
    |> get_content_encodings()
    |> Enum.reduce(encoded_body, &decompress_with_algorithm/2)
  end

  defp get_content_encodings(headers) do
    Enum.find_value(headers, [], fn {name, value} ->
      if String.downcase(name) == "content-encoding" do
        value
        |> String.downcase()
        |> String.split(",", trim: true)
        |> Stream.map(&String.trim/1)
        |> Enum.reverse()
      else
        nil
      end
    end)
  end

  defp decompress_with_algorithm(gzip, body) when gzip in ["gzip", "x-gzip"] do
    :zlib.gunzip(body)
  end

  defp decompress_with_algorithm("deflate", body) do
    :zlib.unzip(body)
  end

  defp decompress_with_algorithm("identity", body) do
    body
  end

  defp decompress_with_algorithm(algorithm, _body) do
    raise "unsupported decompression algorithm: #{inspect(algorithm)}"
  end
end
