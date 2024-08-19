require "placeos-driver"

class Stuff < PlaceOS::Driver
  generic_name :Stuff
  descriptive_name "Driver that does stuff"
  description %(Test driver for testing utility functions)

  default_settings({
    log_lifecycle_hooks: false,
  })

  accessor staff_api : StaffAPI_1

  getter org_zone : Zone { get_org_zone?.not_nil! }
  getter building_zone : Zone { get_building_zone?.not_nil! }

  @log_lifecycle_hooks : Bool = false

  def on_load
    logger.info { "Stuff #on_load" } if @log_lifecycle_hooks

    on_update
  end

  def on_update
    logger.info { "Stuff #on_update" } if @log_lifecycle_hooks

    @log_lifecycle_hooks = setting?(Bool, :log_lifecycle_hooks) || false
    
    @org_zone = nil
    @building_zone = nil
  end

  def on_unload
    logger.info { "Stuff #on_unload" } if @log_lifecycle_hooks
  end

  def connected
    logger.info { "Stuff #connected" } if @log_lifecycle_hooks
  end

  def disconnected
    logger.info { "Stuff #disconnected" } if @log_lifecycle_hooks
  end

  # Finds the org zone for the current location services object
  def get_org_zone? : Zone?
    zones = Array(Zone).from_json staff_api.zones(tags: "org").get.to_json
    zone_ids = zones.map(&.id)
    zone_id = (zone_ids & system.zones).first
    zones.find { |zone| zone.id == zone_id }
  rescue error
    logger.warn(exception: error) { "unable to determine org zone" }
    nil
  end

  # Finds the building zone for the current location services object
  def get_building_zone? : Zone?
    zones = Array(Zone).from_json staff_api.zones(tags: "building").get.to_json
    zone_ids = zones.map(&.id)
    zone_id = (zone_ids & system.zones).first
    zones.find { |zone| zone.id == zone_id }
  rescue error
    logger.warn(exception: error) { "unable to determine building zone" }
    nil
  end
end
