require "placeos-driver"
require "placeos-driver/interface/powerable"
require "placeos-driver/interface/muteable"
require "placeos-driver/interface/switchable"

class Place::EdgeDemo < PlaceOS::Driver
  include Interface::Powerable
  include Interface::Muteable

  enum Input
    VGA         = 0x01
    HDMI        = 0x1A
    HDMI2       = 0x1B
    DisplayPort = 0xA6
    Wireless    = 0x20
  end

  include Interface::InputSelection(Input)

  # Discovery Information
  udp_port 7142
  descriptive_name "Webex Room Display"
  generic_name :Display

  def on_load
    init_state
    schedule.every(10.seconds) { change_input }
    schedule.every(3.seconds) { change_people_count }
  end

  protected def init_state
    self[:power] = false
    self[:input] = Input::DisplayPort
    self[:audio_mute] = false
    self[:video_mute] = false
    self[:people_detected] = 0
    self[:volume] = 0
  end

  protected def change_input
    power(true) unless @power
    switch_to Input.values.sample
  end

  protected def change_people_count
    self[:people_detected] = rand(12)
  end

  def received(data, task)
    logger.warn { "unexpected data received: #{data}" }
    task.try &.success
  end

  @power : Bool = false

  def power(state : Bool)
    self[:power] = @power = state
    logger.debug { state ? "requested to power on" : "requested to power off" }
    state
  end

  def power?
    @power
  end

  def switch_to(input : Input)
    logger.debug { "requested to switch to: #{input}" }
    self[:input] = input
  end

  def volume(value : Int32)
    value = value.clamp(0, 100)
    logger.debug { "requested to set volume: #{value}" }
    self[:volume] = value
  end

  def mute(state : Bool = true, index : Int32 | String = 0, layer : MuteLayer = MuteLayer::AudioVideo)
    logger.debug { "requested to update mute to #{state}" }
    self[:audio_mute] = state
  end
end
