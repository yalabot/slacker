defmodule Slacker do
  defmodule State do
    defstruct [:api_token, :rtm, :state, :rtm_response]
  end

  defmacro __using__(_opts) do
    quote do
      use GenServer
      require Logger
      alias Slacker.Web

      @before_compile unquote(__MODULE__)

      def start_link(slacker_options, options \\ []) do
        GenServer.start_link(__MODULE__, slacker_options, options)
      end

      def init(options) do
        state = options[:state]
        GenServer.cast(self, :connect)
        {:ok, %State{api_token: options.api_token, state: state}}
      end

      def say(slacker, channel, message) do
        GenServer.cast(slacker, {:send_message, channel, message})
      end

      def user_typing(slacker, channel) do
        GenServer.cast(slacker, {:send_user_typing, channel})
      end

      def handle_cast(:connect, state) do
        case Web.auth_test(state.api_token) do
          {:ok, auth} ->
            Logger.info(~s/Successfully authenticated as user "#{auth.user}" on team "#{auth.team}"/)

            {:ok, rtm_response} = Web.rtm_start(state.api_token)
            {:ok, rtm} = Slacker.RTM.start_link(rtm_response.url, self)

            {:noreply, %{state | rtm: rtm, rtm_response: rtm_response}}
          {:error, api_response} ->
            GenServer.cast self, {:auth_error, api_response}
            {:noreply, state}
        end
      end

      def handle_cast({:send_message, channel, msg}, state) do
        GenServer.cast(state.rtm, {:send_message, channel, msg})
        {:noreply, state}
      end

      def handle_cast({:send_user_typing, channel}, state) do
        GenServer.cast(state.rtm, {:send_user_typing, channel})
        {:noreply, state}
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def handle_cast({:handle_incoming, type, msg}, state) do
        if Application.get_env(:slacker, :log_unhandled_events, true) do
          Logger.debug "#{type} -> #{inspect msg}"
        end
        {:noreply, state}
      end

      def handle_cast({:auth_error, api_response}, state) do
        Logger.error("Authentication with the Slack API failed.")
        Logger.error("Error message: #{api_response.body.error}")

        {:stop, {:shutdown, :auth_error}, state}
      end
    end
  end
end
