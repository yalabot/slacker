defmodule Slacker.Web do
  # @moduledoc ~S"""
  #   Slacker.Web is your interface to Slack's "Web API", https://api.slack.com/web

  #   You can call any of the Web API methods on this module as their underscored name
  #   and provide any necessary parameters as a keyword list, ex:

  #     https://api.slack.com/methods/channels.setPurpose
  #     Slacker.Web.channels_set_purpose("your_api_key", channel: "general", purpose: "let's waste time")
  # """

  alias Slacker.WebAPI

  # https://api.slack.com/methods
  @methods [
    "api.test",
    "auth.test",
    "conversations.archive",
    "conversations.close",
    "conversations.create",
    "conversations.history",
    "conversations.info",
    "conversations.invite",
    "conversations.join",
    "conversations.kick",
    "conversations.leave",
    "conversations.list",
    "conversations.mark",
    "conversations.open",
    "conversations.rename",
    "conversations.replies",
    "conversations.setPurpose",
    "conversations.setTopic",
    "conversations.unarchive",
    "chat.delete",
    "chat.postMessage",
    "chat.update",
    "emoji.list",
    "files.delete",
    "files.info",
    "files.list",
    "files.upload",
    "oauth.access",
    "reactions.add",
    "reactions.get",
    "reactions.list",
    "reactions.remove",
    "rtm.start",
    "search.all",
    "search.files",
    "search.messages",
    "stars.list",
    "team.accessLogs",
    "team.info",
    "users.conversations",
    "users.getPresence",
    "users.info",
    "users.list",
    "users.setActive",
    "users.setPresence",
  ]

  Enum.each(@methods, fn(api_method) ->
    method = api_method |> String.replace(".", "_") |> Inflex.underscore
    method_name = String.to_atom method

    def unquote(method_name)(api_token, params \\ [])
    def unquote(method_name)(api_token, params) when is_map(params) do
      unquote(method_name)(api_token, Map.to_list(params))
    end
    def unquote(method_name)(api_token, params) do
      body = params
      |> Keyword.put(:token, api_token)

      # {:form, body} is a hackney expression
      WebAPI.post(unquote(api_method), {:form, body})
    end
  end)
end
