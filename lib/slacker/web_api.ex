defmodule Slacker.WebAPI do
  require Logger
  use HTTPoison.Base

  @url_base Application.get_env(:slacker, :url_base) || "https://slack.com/api/"

  def post(path, body, headers \\ [], hackney_opts \\ [ssl: [{:versions, [:'tlsv1.2']}]]) do
    path
    |> super(body, headers, hackney_opts)
    |> check_response
  end

  def process_url(path) do
    @url_base <> path
  end

  def process_response_body(body) do
    try do
      body
      |> Poison.decode!
      |> Enum.reduce(%{}, fn {k, v}, map -> Map.put(map, String.to_atom(k), v) end)
    rescue
      x in [Poison.SyntaxError] ->
        Logger.error(Exception.message(x))
        Logger.error("body:")
        Logger.error(inspect(body))
        body
    end
  end

  defp check_response({:ok, %{status_code: 200, body: %{ok: true} = body}}) do
    {:ok, body}
  end
  defp check_response({_, response}), do: {:error, response}
end
