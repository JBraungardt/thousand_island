defmodule ThousandIsland.Socket do
  @moduledoc """
  Encapsulates a client connection's underlying socket, providing a facility to
  read, write, and otherwise manipulate a connection from a client.
  """

  defstruct socket: nil,
            transport_module: nil,
            read_timeout: nil

  @typedoc "A reference to a socket along with metadata describing how to use it"
  @type t :: %__MODULE__{
          socket: ThousandIsland.Transport.socket(),
          transport_module: module(),
          read_timeout: timeout()
        }

  @doc false
  @spec new(
          ThousandIsland.Transport.socket(),
          ThousandIsland.ServerConfig.t()
        ) ::
          t()
  def new(socket, server_config) do
    %__MODULE__{
      socket: socket,
      transport_module: server_config.transport_module,
      read_timeout: server_config.read_timeout
    }
  end

  @doc """
  Handshakes the underlying socket if it is required (as in the case of SSL sockets, for example).

  This is normally called internally by `ThousandIsland.Handler` and does not need to be
  called by implementations which are based on `ThousandIsland.Handler`
  """
  @spec handshake(t()) :: ThousandIsland.Transport.on_handshake()
  def handshake(%__MODULE__{} = socket) do
    case socket.transport_module.handshake(socket.socket) do
      {:ok, _} -> {:ok, socket}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Returns available bytes on the given socket. Up to `length` bytes will be
  returned (0 can be passed in to get the next 'available' bytes, typically the
  next packet). If insufficient bytes are available, the function can wait `timeout`
  milliseconds for data to arrive.
  """
  @spec recv(t(), non_neg_integer(), timeout() | nil) :: ThousandIsland.Transport.on_recv()
  def recv(%__MODULE__{} = socket, length \\ 0, timeout \\ nil) do
    case socket.transport_module.recv(socket.socket, length, timeout || socket.read_timeout) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Sends the given data (specified as a binary or an IO list) on the given socket.
  """
  @spec send(t(), IO.chardata()) :: ThousandIsland.Transport.on_send()
  def send(%__MODULE__{} = socket, data) do
    case socket.transport_module.send(socket.socket, data) do
      :ok -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Sends the contents of the given file based on the provided offset & length
  """
  @spec sendfile(t(), String.t(), non_neg_integer(), non_neg_integer()) ::
          ThousandIsland.Transport.on_sendfile()
  def sendfile(%__MODULE__{} = socket, filename, offset, length) do
    case socket.transport_module.sendfile(socket.socket, filename, offset, length) do
      {:ok, bytes_written} -> {:ok, bytes_written}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Shuts down the socket in the given direction.
  """
  @spec shutdown(t(), ThousandIsland.Transport.way()) :: ThousandIsland.Transport.on_shutdown()
  def shutdown(%__MODULE__{} = socket, way) do
    socket.transport_module.shutdown(socket.socket, way)
  end

  @doc """
  Closes the given socket. Note that a socket is automatically closed when the handler
  process which owns it terminates
  """
  @spec close(t()) :: ThousandIsland.Transport.on_close()
  def close(%__MODULE__{} = socket) do
    socket.transport_module.close(socket.socket)
  end

  @doc """
  Gets the given flags on the socket

  Errors are usually from :inet.posix(), however, SSL module defines return type as any()
  """
  @spec getopts(t(), ThousandIsland.Transport.socket_get_options()) ::
          ThousandIsland.Transport.on_getopts()
  def getopts(%__MODULE__{} = socket, options) do
    socket.transport_module.getopts(socket.socket, options)
  end

  @doc """
  Sets the given flags on the socket

  Errors are usually from :inet.posix(), however, SSL module defines return type as any()
  """
  @spec setopts(t(), ThousandIsland.Transport.socket_set_options()) ::
          ThousandIsland.Transport.on_setopts()
  def setopts(%__MODULE__{} = socket, options) do
    socket.transport_module.setopts(socket.socket, options)
  end

  @doc """
  Returns information in the form of `t:ThousandIsland.Transport.socket_info()` about the local end of the socket.
  """
  @spec local_info(t()) :: ThousandIsland.Transport.socket_info()
  def local_info(%__MODULE__{} = socket) do
    socket.transport_module.local_info(socket.socket)
  end

  @doc """
  Returns information in the form of `t:ThousandIsland.Transport.socket_info()` about the remote end of the socket.
  """
  @spec peer_info(t()) :: ThousandIsland.Transport.socket_info()
  def peer_info(%__MODULE__{} = socket) do
    socket.transport_module.peer_info(socket.socket)
  end

  @doc """
  Returns whether or not this protocol is secure.
  """
  @spec secure?(t()) :: boolean()
  def secure?(%__MODULE__{} = socket) do
    socket.transport_module.secure?()
  end

  @doc """
  Returns statistics about the connection.
  """
  @spec getstat(t()) :: ThousandIsland.Transport.socket_stats()
  def getstat(%__MODULE__{} = socket) do
    socket.transport_module.getstat(socket.socket)
  end

  @doc """
  Returns information about the protocol negotiated during transport handshaking (if any).
  """
  @spec negotiated_protocol(t()) :: ThousandIsland.Transport.negotiated_protocol_info()
  def negotiated_protocol(%__MODULE__{} = socket) do
    socket.transport_module.negotiated_protocol(socket.socket)
  end
end
