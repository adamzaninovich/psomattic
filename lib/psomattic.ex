defmodule Psomattic do
  @moduledoc """
  Documentation for `Psomattic`.
  """

  @doc """
  Checks BesyBuy website and returns :sold_out or :in_stock

  Returns Parse Error if response cannot be parsed
  """
  @spec best_buy :: :sold_out | :in_stock | {:error, String.t()}
  def best_buy do
    url = "https://www.bestbuy.com/site/sony-playstation-5-console/6426149.p?skuId=6426149"

    with {:ok, document} <- get_document(url) do
      text =
        document
        |> Floki.find(".add-to-cart-button")
        |> Floki.text()
        |> String.downcase()

      case text do
        "sold out" -> :sold_out
        _any_other -> :in_stock
      end
    else
      error -> {:error, "Parse Error: #{inspect(error)}"}
    end
  end

  defp get_document(url) do
    url
    |> Psomattic.Client.make_request!()
    |> Floki.parse_document()
  end
end
