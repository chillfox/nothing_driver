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

  # Finds the org zone id for the current location services object
  def get_org_zone_id? : String?
    zone_ids = staff_api.zones(tags: "org").get.as_a.map(&.[]("id").as_s)
    (zone_ids & system.zones).first
  rescue error
    logger.warn(exception: error) { "unable to determine org zone id" }
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

  def get_email_template_fields : Hash(String, TemplateFields)
    metadata = Metadata.from_json staff_api.metadata(org_zone.id, "email_template_fields").get["email_template_fields"].to_json
    Hash(String, TemplateFields).from_json metadata.details.to_json
  end

  def update_email_template_fields
    # template_fields : Hash(String, TemplateFields)
    template_fields = get_email_template_fields

    # write_metadata(id : String, key : String, payload : JSON::Any, description : String = "")
    staff_api.write_metadata(id: org_zone.id, key: "email_template_fields_test", payload: template_fields, description: "Available fields for use in email templates").get
  end

  def get_email_templates
    staff_api.metadata(org_zone.id, "email_templates").get
  rescue error
    logger.warn(exception: error) { "unable to get email templates" }
    nil
  end

  def get_email_templates_on_building_zone
    staff_api.metadata(building_zone.id, "email_templates").get
  rescue error
    logger.warn(exception: error) { "unable to get email templates" }
    nil
  end

  struct Zone
    include JSON::Serializable

    property id : String

    property name : String
    property description : String
    property tags : Set(String)
    property location : String?
    property display_name : String?
    property code : String?
    property type : String?
    property count : Int32 = 0
    property capacity : Int32 = 0
    property map_id : String?
    property timezone : String?

    property parent_id : String?

    @[JSON::Field(ignore: true)]
    @time_location : Time::Location?

    def time_location? : Time::Location?
      if tz = timezone.presence
        @time_location ||= Time::Location.load(tz)
      end
    end

    def time_location! : Time::Location
      time_location?.not_nil!
    end
  end

  # {
  #     "email_template_fields": {
  #         "name": "email_template_fields",
  #         "description": "",
  #         "details": {
  #             "template_name_key": {
  #                 "name": "Visitor Invite",
  #                 "fields": [
  #                     {
  #                         "name": "building_name",
  #                         "description": "the name of the building"
  #                     }
  #                 ]
  #             }
  #         },
  #         "parent_id": "zone-1234",
  #         "editors": [],
  #         "modified_by_id": "user-1234"
  #     }
  # }

  struct Metadata
    include JSON::Serializable

    property name : String
    property description : String = ""
    property details : JSON::Any
    property parent_id : String
    property schema_id : String? = nil
    property editors : Set(String) = Set(String).new
    property modified_by_id : String? = nil
  end

  record TemplateFields, name : String, fields : Array(TemplateField) do
    include JSON::Serializable
  end

  record TemplateField, name : String, description : String do
    include JSON::Serializable
  end
end
