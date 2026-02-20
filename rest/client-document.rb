#!/usr/bin/ruby
require 'httpclient'

# 変換対象のHTML
data = <<DATA
<html>
<body>
RubyからCopper PDFを使う。
</body>
</html>
DATA

# POSTの準備
client = HTTPClient.new
postdata = {
  'rest.user' => 'user',
  'rest.password' => 'kappa',
  'rest.main' => data,
}

# 大きなデータを扱えるようにmultipart/formdataで送信(boundaryは適当な文字列）
boundary = '3w48588hfwfdwed2332hdiuj2d3jiuhd32'
puts client.post_content('http://localhost:8097/transcode', postdata,
'content-type' => 'multipart/form-data, boundary=#{boundary}')
