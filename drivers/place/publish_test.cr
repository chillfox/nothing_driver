require "placeos-driver"

class Place::AcidTest < PlaceOS::Driver
  descriptive_name "PlaceOS Publish Test"
  generic_name :Publish

  @count : UInt64 = 0

  def on_load
    schedule.every(5.seconds) do
      publish("message/channel", "a message")
      @count += 1
      self[:counter] = @count
    end
  end

  def perform_publish(channel : String, message : String)
    publish(channel, message)
    message
  end

  def set_status(name : String, value : JSON::Any?)
    self[name] = value
  end
end
