require "placeos-driver/spec"

DriverSpecs.mock_driver "Crash" do
  settings({
    log_lifecycle_hooks: true,
  })

  exec :on_load
  exec :on_update
  exec :on_unload
  exec :connected
  exec :disconnected
end
