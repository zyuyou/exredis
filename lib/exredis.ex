defmodule Exredis do
  @moduledoc """
  Redis client for Elixir
  """

  defmacro __using__(_opts) do
    quote do
      import Exredis
    end
  end

  @type reconnect_sleep :: :no_reconnect | integer
  @type start_link      :: { :ok, pid } | { :error, term }


  @doc """
  Connects to the Redis server using a connection string:

  * `start_using_connection_string("redis://user:password@127.0.0.1:6379/0")`
  * `start_using_connection_string("redis://127.0.0.1:6379")`

  Returns the pid of the connected client.
  """
  @spec start_using_connection_string(binary, :no_reconnect | integer) :: pid
  def start_using_connection_string(connection_string, reconnect_sleep \\ :no_reconnect)  do
    config = Exredis.ConnectionString.parse(connection_string)
    start(config.host, config.port, config.db, config.password, reconnect_sleep)
  end

  @doc """
  Connects to the Redis server:

  * `start`
  * `start("127.0.0.1", 6379)`

  Returns the pid of the connected client.
  """
  @spec start(binary, integer, integer, binary, :no_reconnect | integer) :: pid
  def start(host \\ "127.0.0.1", port \\ 6379, database \\ 0,
            password \\ "", reconnect_sleep \\ :no_reconnect), do:
    start_link(host, port, database, password, reconnect_sleep)
    |> elem 1

  @doc """
  Connects to the Redis server, Erlang way:

  * `start_link`
  * `start_link("127.0.0.1", 6379)`

  Returns a tuple `{:ok, pid}`.
  """
  @spec start_link(binary, integer, integer, binary, reconnect_sleep) :: start_link
  def start_link(host \\ "127.0.0.1", port \\ 6379, database \\ 0,
                 password \\ "", reconnect_sleep \\ :no_reconnect), do:
    :eredis.start_link(String.to_char_list(host), port, database, String.to_char_list(password), reconnect_sleep)

  @doc """
  Disconnects from the Redis server:

  `stop client`

  `client` is a `pid` like the one returned by `Exredis.start`.
  """
  @spec stop(pid) :: :ok
  def stop(client), do:
    client |> :eredis.stop

  @doc """
  Performs a query with the given arguments on the connected `client`.

  * `query(client, ["SET", "foo", "bar"])`
  * `query(client, ["GET", "foo"])`
  * `query(client, ["MSET" | ["k1", "v1", "k2", "v2", "k3", "v3"]])`
  * `query(client, ["MGET" | ["k1", "k2", "k3"]])`

  See all the available commands in the [official Redis
  documentation](http://redis.io/commands).
  """
  @spec query(pid, list) :: any
  def query(client, command) when is_pid(client) and is_list(command), do:
    client |> :eredis.q(command) |> elem(1)

  @doc """
  Performs a pipeline query, executing the list of commands.

      query_pipe(client, [["SET", :a, "1"],
                          ["LPUSH", :b, "3"],
                          ["LPUSH", :b, "2"]])
  """
  @spec query_pipe(pid, [list]) :: any
  def query_pipe(client, command) when is_pid(client) and is_list(command), do:
    client |> :eredis.qp(command)
end
