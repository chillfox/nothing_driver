require "placeos-driver"

class Crash < PlaceOS::Driver
  generic_name :Crash
  descriptive_name "Crash Test Driver"
  description %(Test driver for testing driver crashes)

  default_settings({
    log_lifecycle_hooks:   false,
    crash_on_load:         false,
    crash_on_update:       false,
    crash_on_unload:       false,
    crash_on_connected:    false,
    crash_on_disconnected: false,
    crash_timezone:        "GMT",
    crash_schedule:        "*/1 * * * *",
    crash_delay:           10,
  })

  @log_lifecycle_hooks : Bool = false
  @crash_on_load : Bool = false
  @crash_on_update : Bool = false
  @crash_on_unload : Bool = false
  @crash_on_connected : Bool = false
  @crash_on_disconnected : Bool = false
  @crash_timezone : Time::Location = Time::Location.load("GMT")
  @crash_schedule : String? = nil
  @crash_delay : Int32 = 10

  def on_load
    logger.info { "Stuff #on_load" } if @log_lifecycle_hooks

    crash("load") if @crash_on_load
    on_update
  end

  def on_update
    logger.info { "Stuff #on_update" } if @log_lifecycle_hooks

    @log_lifecycle_hooks = setting?(Bool, :log_lifecycle_hooks) || false
    @crash_on_load = setting?(Bool, :crash_on_load) || false
    @crash_on_update = setting?(Bool, :crash_on_update) || false
    @crash_on_unload = setting?(Bool, :crash_on_unload) || false
    @crash_on_connected = setting?(Bool, :crash_on_connected) || false
    @crash_on_disconnected = setting?(Bool, :crash_on_disconnected) || false

    crash_timezone = setting?(String, :crash_timezone).presence || "GMT"
    @crash_timezone = Time::Location.load(crash_timezone)

    @crash_schedule = setting?(String, :crash_schedule).presence
    @crash_delay = setting?(Int32, :crash_delay) || 10

    crash("update") if @crash_on_update

    schedule.clear
    if cron = @crash_schedule
      schedule.cron(cron, @crash_timezone) { crash("schedule") }
    end
  end

  def on_unload
    logger.info { "Stuff #on_unload" } if @log_lifecycle_hooks

    crash("unload") if @crash_on_unload
  end

  def connected
    logger.info { "Stuff #connected" } if @log_lifecycle_hooks

    crash("connected") if @crash_on_connected
  end

  def disconnected
    logger.info { "Stuff #disconnected" } if @log_lifecycle_hooks

    crash("disconnected") if @crash_on_disconnected
  end

  def crash(on : String = "?")
    logger.fatal { "Crashing! on #{on}" }
    logger.info { "delaying crash for #{@crash_delay} seconds" } if @crash_delay > 0
    sleep(@crash_delay)
    raise "Crash! on #{on}"
  end
end
