require "placeos-driver/spec"

class PrivateHelper < DriverSpecs::MockDriver
  def used_for_place_testing
    logger.debug { "this will be propagated to backoffice!" }
    "you can delete this file"
  end

  def echo(input : String)
    logger.debug { input }
    input
  end
end

DriverSpecs.mock_driver "Place::AcidTest" do
  system({
    Helper: {PrivateHelper},
  })

  # Test calling other drivers
  exec(:echo, "a quick message").get.should eq("a quick message")

  # Test timers
  exec(:start_timer, 1).get
  sleep 3.5
  exec(:stop_timer, 1).get
  (status[:timer_count].as_i > 2).should eq(true)

  # Test channel data
  exec(:send_to_channel, "some data").get
  status[:channel_data].should eq("some data")
end
