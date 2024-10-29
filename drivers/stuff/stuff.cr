require "placeos-driver"
require "placeos-driver/interface/mailer"
require "placeos-driver/interface/mailer_templates"

class Stuff < PlaceOS::Driver
  include PlaceOS::Driver::Interface::MailerTemplates

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

  # def get_email_template_fields : Hash(String, TemplateFields)
  #   metadata = Metadata.from_json staff_api.metadata(org_zone.id, "email_template_fields").get["email_template_fields"].to_json
  #   Hash(String, TemplateFields).from_json metadata.details.to_json
  # end

  # def update_email_template_fields
  #   # template_fields : Hash(String, TemplateFields)
  #   template_fields = get_email_template_fields

  #   # write_metadata(id : String, key : String, payload : JSON::Any, description : String = "")
  #   staff_api.write_metadata(id: org_zone.id, key: "email_template_fields_test", payload: template_fields, description: "Available fields for use in email templates").get
  # end

  # def get_email_templates_on_org_zone?
  #   staff_api.metadata(org_zone.id, "email_templates").get
  # rescue error
  #   logger.warn(exception: error) { "unable to get email templates" }
  #   nil
  # end

  # def get_email_templates_on_building_zone
  #   staff_api.metadata(building_zone.id, "email_templates").get
  # rescue error
  #   logger.warn(exception: error) { "unable to get email templates" }
  #   nil
  # end

  # def get_email_templates?(zone_id : String) : Array(EmailTemplate)?
  #   metadata = Metadata.from_json staff_api.metadata(zone_id, "email_templates").get["email_templates"].to_json
  #   metadata.details.as_a.map { |template| EmailTemplate.from_json template.to_json }
  # rescue error
  #   logger.warn(exception: error) { "unable to get email templates from zone #{zone_id} metadata" }
  #   nil
  # end

  def list_mailer_drivers
    mailers = system.implementing(Interface::Mailer)
    logger.info { "Found #{mailers.size} mailer drivers" }
    mailers.map { |mailer| mailer.module_name }
  end

  SEPERATOR = "."

  def find_template_fields
    template_fields : Hash(String, MetadataTemplateFields) = Hash(String, MetadataTemplateFields).new

    system.implementing(Interface::MailerTemplates).each do |driver|
      # TODO: next if the driver is not turned on
      begin
        driver_template_fields = Array(TemplateFields).from_json driver.template_fields.get.to_json
      rescue error
        logger.warn(exception: error) { "unable to get email template fields from module #{driver.module_id}" }
        next
      end

      driver_template_fields.each do |field_list|
        template_fields["#{field_list[:trigger].join(SEPERATOR)}"] = MetadataTemplateFields.new(
          module_name: driver.module_name,
          name: "#{driver.module_name}: #{field_list[:name]}",
          description: field_list[:description],
          fields: field_list[:fields],
        )
      end
    end

    self[:template_fields] = template_fields
  end

  def template_fields : Array(TemplateFields)
    [] of TemplateFields
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

  # record TemplateFields, name : String, fields : Array(TemplateField) do
  #   include JSON::Serializable
  # end

  # record TemplateField, name : String, description : String do
  #   include JSON::Serializable
  # end

  struct MetadataTemplateFields
    include JSON::Serializable

    property module_name : String = ""
    property name : String = ""
    property description : String? = nil
    property fields : Array(NamedTuple(name: String, description: String)) = [] of NamedTuple(name: String, description: String)

    def initialize(
      @module_name : String,
      @name : String,
      @description : String? = nil,
      @fields : Array(NamedTuple(name: String, description: String)) = [] of NamedTuple(name: String, description: String)
    )
    end
  end

  struct EmailTemplate
    include JSON::Serializable

    # property id : String
    # property from : String
    # property html : String
    property text : String
    property subject : String
    # property trigger : String
    # property zone_id : String
    # property category : String
    # property reply_to : String
    # property created_at : Int64
    # property updated_at : Int64
  end
end
