require "placeos-driver/spec"

# Manual Compile:
# export COMPILE_DRIVER=drivers/place/private_helper_spec.cr
# crystal build -o exec_name ./src/build.cr
DriverSpecs.mock_driver "Place::PrivateHelper" do
  resp = exec :echo, "message"
  resp.get.should eq "message"
end
