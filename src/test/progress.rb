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
  # 出力しない
  session.set_results(Results::SingleResult.new(Builder::NullBuilder.new))

  # メッセージ
  session.receive_progress do |length, read|
    puts "#{read} / #{length}"
  end

  #リソースのアクセス許可
  session.property('input.include', 'http://www.w3.org/**')
    
  #文書の送信
  session.transcode_server('http://www.w3.org/TR/xslt');
end
