defmodule Plowman.Dynohost do
  import Plowman.Config, only: [config: 1]
  alias Plowman.GitCli.CliState, as: CliState
  alias Plowman.Connection, as: Connection
  alias Plowman.GenServer, as: PlowmanGenServer

  @server __MODULE__
  use GenServer.Behaviour

  defrecord SslState, [:socket, :listener, :client]

  # Api
  def start_link(host, CliState[] = client) do
    PlowmanGenServer.start_link(@server, [host, client], [])
  end

  def send(dyno, data) do
    PlowmanGenServer.cast(dyno, {:send, data})
  end

  def auth(dyno, credentials) do
    send(dyno, credentials)
  end

  ## callback functions
  def init([host, client]) do
    port = config(:dynohost)[:rendezvous_port]
    {:ok, socket} = :ssl.connect('#{host}', port, [])
    state = SslState.new(socket: socket, client: client)

    state = state.listener(Process.spawn(__MODULE__, :ssl_receive, [state]))
    :ssl.controlling_process(state.socket, state.listener)

    {:ok, state}
  end

  def terminate(_reason, state) do
    state.listener <- :stop
    :ok
  end

  def handle_cast({:send, data}, state) do
    state.listener <- {:send, state.socket, data}
    {:noreply, state}
  end

  def ssl_receive(SslState[socket: socket, client: client] = state) do
    receive do
      {:send, ^socket, data} ->
        :ssl.send(socket, data)
        ssl_receive(state)
      {:ssl, ^socket, data} ->
        Connection.forward(client, list_to_binary(data))
        ssl_receive(state)
      {:ssl_closed, ^socket} ->
        Connection.forward(client, :eof)
      {:ssl_error, ^socket, reason}->
        Connection.forward(client, {:error, reason})
      {:stop} ->
        :ok
    end
  end
end
