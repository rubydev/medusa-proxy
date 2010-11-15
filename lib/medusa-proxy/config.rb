module Medusa
  # $ bin/medusa start -- test
  if ENV['MEDUSA_ENV'] == 'test'
    require 'fakeweb'
    json = %Q|[{"url" : "http://190.152.146.74:80"}, {"url" : "http://82.119.76.144:80" }, {"url" : "http://67.208.112.173:80"}]|
    FakeWeb.register_uri(:get, PROXY_LIST_URL, :body => json)
  end

  if ENV['MEDUSA_ENV'] == 'development'
    BACKENDS = [
      {:url => 'http://190.152.146.74:80'},
      {:url => 'http://82.119.76.144:80' },
      {:url => 'http://67.208.112.173:80'}
    ]
  else
    begin
      list = RestClient.get PROXY_LIST_URL, {:accept => :json}
      BACKENDS = Yajl::Parser.parse(list, :symbolize_keys => true)
    rescue Exception => e
      puts "[!] Cannot load proxy list configuration from #{PROXY_LIST_URL}", "\n"
      raise e
    end
  end

end
