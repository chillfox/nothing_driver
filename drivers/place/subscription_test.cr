require "placeos-driver"

class Place::SubscribeTest < PlaceOS::Driver
  descriptive_name "PlaceOS Subscribe Test"
  generic_name :Subscribe

  def subscribe_to(mod : String, status : String)
    system[mod].subscribe(status) do |_sub, payload|
      logger.debug { "state update of #{mod}.#{status}:\n#{payload}" }
    end
    "#{mod}.#{status}"
  end

  def monitor_channel(name : String)
    monitor(name) do |_sub, payload|
      logger.debug { "received message from #{name}:\n#{payload}" }
    end
    name
  end

  def unsubscribe_all
    subscriptions.clear
  end
end
