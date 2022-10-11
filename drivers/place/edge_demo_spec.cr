require "placeos-driver/spec"

DriverSpecs.mock_driver "Place::EdgeDemo" do
  exec(:power, true).get
  status[:power].should eq(true)
end
