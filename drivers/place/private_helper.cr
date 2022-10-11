require "placeos-driver"
require "base62"

class Place::PrivateHelper < PlaceOS::Driver
  descriptive_name "PlaceOS Test Helper"
  generic_name :Helper

  def used_for_place_testing
    logger.debug { "this will be propagated to backoffice!" }
    "you can delete this file"
  end

  def echo(input : String)
    logger.debug { input }
    input
  end
end
