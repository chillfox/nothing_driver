require "placeos-driver"

class Nothing < PlaceOS::Driver
  generic_name :Nothing
  descriptive_name "Driver that does nothing"
  default_settings({
    do_something: false,
  })

  @do_something : Bool = false

  def on_load
    logger.info { "Nothing #on_load" }
  end

  def on_update
    logger.info { "Nothing #on_update" }

    @do_something = setting?(Bool, :do_something) || false
    schedule.every(5.minutes) { pretend_to_do_something } if do_something
  end

  def on_unload
    logger.info { "Nothing #on_unload" }
  end

  def connected
    logger.info { "Nothing #connected" }
  end

  def disconnected
    logger.info { "Nothing #disconnected" }
  end

  def pretend_to_do_something
    logger.notice { "Nothing pretending to do something!" }
  end

  # Test methods
  def get_system_zones
    system.zones
  end
end
