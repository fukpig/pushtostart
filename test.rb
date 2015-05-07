require 'rubygems'
require 'eventmachine'

EventMachine.run do
    EM.add_periodic_timer(1) { puts "Tick ..." }
end