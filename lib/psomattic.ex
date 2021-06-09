defmodule Psomattic do
  @moduledoc """
  Documentation for `Psomattic`.
  """

  @check_data [
    {
      "Best Buy",
      "https://www.bestbuy.com/site/sony-playstation-5-console/6426149.p?skuId=6426149",
      ".add-to-cart-button",
      ~r/sold out/i,
      ".priceView-customer-price span:first-child"
    },
    {
      "Amazon",
      "https://www.amazon.com/PlayStation-5-Console/dp/B08FC5L3RG",
      "#availability span:first-child",
      ~r/currently unavailable/i,
      "#priceblock_ourprice"
    },
    {
      "Walmart - Standard Edition",
      "https://www.walmart.com/ip/Sony-PlayStation-5-Video-Game-Console/363472942",
      ".prod-PriceSection .prod-blitz-copy-message",
      ~r/this item is out of stock/i,
      ".prod-PriceSection .prod-PriceHero .hide-content-m .price .visuallyhidden"
    },
    {
      "Walmart - Digital Edition",
      "https://www.walmart.com/ip/Sony-PlayStation-5-Digital-Edition/493824815",
      ".prod-PriceSection .prod-blitz-copy-message",
      ~r/this item is out of stock/i,
      ".prod-PriceSection .prod-PriceHero .hide-content-m .price .visuallyhidden"
    }
  ]

  @doc """
  Returns a map of each store and its stock status and price
  """
  def apply_checks() do
    tasks =
      for {name, url, stock_selector, stock_matcher, price_selector} <- @check_data do
        ref =
          Task.async(fn ->
            check(url, stock_selector, stock_matcher, price_selector)
          end)

        {name, ref}
      end

    for {name, task} <- tasks, into: %{} do
      {name, Task.await(task)}
    end
  end

  @doc """
  Checks a website and returns :sold_out or :in_stock

  Returns Parse Error if response cannot be parsed
  """
  def check(url, stock_selector, stock_matcher, price_selector) do
    with {:ok, document} <- get_document(url) do
      stock_status = get_stock_status(document, stock_selector, stock_matcher)
      price = get_price(document, price_selector)

      {stock_status, price}
    else
      error -> {:error, "Parse Error: #{inspect(error)}"}
    end
  end

  defp get_document(url) do
    url
    |> Psomattic.Client.make_request!()
    |> Floki.parse_document()
  end

  defp get_stock_status(document, stock_selector, stock_matcher) do
    text =
      document
      |> Floki.find(stock_selector)
      |> Floki.text()
      |> String.downcase()

    cond do
      String.match?(text, stock_matcher) -> :sold_out
      :any_other -> :in_stock
    end
  end

  defp get_price(document, price_selector) do
    document
    |> Floki.find(price_selector)
    |> Floki.text()
    |> String.trim_leading("$")
    |> check_price()
  end

  defp check_price(""), do: :unavailable
  defp check_price(price), do: price
end
