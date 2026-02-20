#!/usr/bin/ruby
require '../code/CTI'
include CTI

# セッションの開始
get_session('ctip://localhost:8099/',
{
  'user' => 'user',
  'password' => 'kappa'
}
) do |session|
  # リソースの送信
  session.resource('test.css') do |out|
    copy_stream(File.open('data/test.css'), out)
  end

  # 文書の送信
  session.transcode do |out|
    copy_stream(File.open('data/test.html'), out)
  end
end
