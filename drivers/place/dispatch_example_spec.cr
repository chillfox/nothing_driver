require "placeos-driver/spec"
require "bindata"

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

DriverSpecs.mock_driver "Place::DispatchExample" do
  status[:connections].should eq(0)

  # establish a new connection
  payload = DispatchProtocol.new
  payload.message = DispatchProtocol::MessageType::OPENED
  payload.ip_address = "10.0.0.1"
  payload.id_or_port = 2_u64

  transmit(payload.to_slice)

  status[:connections].should eq(1)
  exec(:connected_to?).get.should eq(["10.0.0.1"])

  # check keepalive is working
  payload = DispatchProtocol.new
  payload.message = DispatchProtocol::MessageType::WRITE
  payload.ip_address = "10.0.0.1"
  payload.id_or_port = 2_u64
  payload.data = "\r".to_slice

  exec(:send_keepalive)
  should_send(payload.to_slice)

  # check notify actions work
  payload = DispatchProtocol.new
  payload.message = DispatchProtocol::MessageType::WRITE
  payload.ip_address = "10.0.0.1"
  payload.id_or_port = 2_u64
  payload.data = %({"room":"1234","action":"reset"}\r).to_slice

  exec(:notify_action, "reset", "1234")
  should_send(payload.to_slice)

  # check disconnect is acknowledged
  payload = DispatchProtocol.new
  payload.message = DispatchProtocol::MessageType::CLOSED
  payload.ip_address = "10.0.0.1"
  payload.id_or_port = 2_u64

  transmit(payload.to_slice)
  status[:connections].should eq(0)
end
