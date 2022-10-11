require "placeos-driver"
require "bindata"

class Place::DispatchExample < PlaceOS::Driver
  generic_name :DispatchExample
  descriptive_name "External API Connector"
  description %(accepts whitelisted connections from external devices for sending events)

  # Hookup dispatch to accept incomming connections
  uri_base "ws://dispatch/api/dispatch/v1/tcp_dispatch?port=2020&accept=192.168.0.1"

  default_settings({
    dispatcher_key:   "secret",
    keepalive_period: 10,
  })

  def websocket_headers
    dispatcher_key = setting?(String, :dispatcher_key)
    HTTP::Headers{
      "Authorization" => "Bearer #{dispatcher_key}",
      "X-Module-ID"   => module_id,
    }
  end

  @connections : Hash(UInt64, String) = {} of UInt64 => String

  def on_load
    self[:connections] = 0
    on_update
  end

  def on_update
    keepalive_period = setting?(UInt32, :keepalive_period) || 10
    schedule.clear
    schedule.every(keepalive_period.seconds) { send_keepalive }
  end

  def disconnected
    @connections = {} of UInt64 => String
    self[:connections] = 0
  end

  def connected_to?
    @connections.values
  end

  KEEPALIVE = "\r".to_slice

  def send_keepalive
    logger.debug { "sending keepalive" }
    @connections.each do |id, ip|
      payload = DispatchProtocol.new
      payload.message = DispatchProtocol::MessageType::WRITE
      payload.ip_address = ip
      payload.id_or_port = id
      payload.data = KEEPALIVE

      # explicitly using transport here as we're not expecting replies
      transport.send payload.to_slice
    end
  end

  enum Action
    Reset   # meeting ended
    Prepare # meeting about to start
  end

  def notify_action(action : Action, room : String)
    message = {room: room, action: action}.to_json
    message = "#{message}\r".to_slice

    @connections.each do |id, ip|
      payload = DispatchProtocol.new
      payload.message = DispatchProtocol::MessageType::WRITE
      payload.ip_address = ip
      payload.id_or_port = id
      payload.data = message
      transport.send payload.to_slice
    end
  end

  def received(data, task)
    protocol = IO::Memory.new(data).read_bytes(DispatchProtocol)

    logger.debug { "received message: #{protocol.message} #{protocol.ip_address}:#{protocol.id_or_port} (size #{protocol.data_size})" }

    case protocol.message
    when .opened?
      @connections[protocol.id_or_port] = protocol.ip_address
      self[:connections] = @connections.size
    when .closed?
      @connections.delete protocol.id_or_port
      self[:connections] = @connections.size
    when .received?
      logger.debug { "received from #{protocol.ip_address}: #{String.new(protocol.data)}" }
    else
      raise "unexpected message type: #{protocol.message}"
    end

    task.try &.success
  end

  class DispatchProtocol < BinData
    endian big

    enum MessageType
      OPENED
      CLOSED
      RECEIVED
      WRITE
      CLOSE
    end

    enum_field UInt8, message : MessageType = MessageType::RECEIVED
    string :ip_address
    uint64 :id_or_port
    uint32 :data_size, value: ->{ data.size }
    bytes :data, length: ->{ data_size }, default: Bytes.new(0)
  end
end
