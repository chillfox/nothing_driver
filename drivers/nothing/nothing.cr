require "placeos-driver"

class Nothing < PlaceOS::Driver
  generic_name :Nothing
  descriptive_name "Driver that does nothing"

  default_settings({
    do_something: false,
  })

  def on_load
    logger.info { "Nothing #on_load" }
  end

  def on_update
    logger.info { "Nothing #on_update" }
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
end
