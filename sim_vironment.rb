require 'rubygems/specification'
data = File.read('poolparty.gemspec')
spec = nil
Thread.new { spec = eval("$SAFE = 3\n#{data}") }.join
puts spec