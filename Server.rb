require 'socket'
require 'date'




server = TCPServer.new 2000
puts "Running..."
loop do
    Thread.start(server.accept) do |client|
        response = client.gets
        client.close
		time = DateTime.now
        puts "#{time} #{response}"
        log = File.open("Keystore.txt", "a")
        log.puts "#{time} #{response}"
        log.close
    end
end