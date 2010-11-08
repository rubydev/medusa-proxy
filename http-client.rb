require 'net/http'

proxy = Net::HTTP::Proxy('0.0.0.0', '9999')

proxy.start('www.example.com') do |http|
  puts http.get('/').body
end
