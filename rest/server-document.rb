#!/usr/bin/ruby
require 'httpclient'

# POSTの準備
client = HTTPClient.new
postdata = {
  'rest.user' => 'user',
  'rest.password' => 'kappa',
  'input.include' => 'http://copper-pdf.com/**',
  'rest.mainURI' => 'http://copper-pdf.com/',
}

# POSTを実行
puts client.post_content('http://localhost:8097/transcode', postdata)
