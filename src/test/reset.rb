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
  # ファイル出力
  dir = 'out';
  Dir::mkdir(dir, 0777) unless File.exist?(dir)
  session.set_output_as_file('out/reset-1.pdf')

  # リソースの送信
  session.resource('test.css') do |out|
    copy_stream(File.open('data/test.css'), out)
  end

  # 文書の送信
  session.transcode('test.html') do |out|
    copy_stream(File.open('data/test.html'), out)
  end

  # 事前に送って変換
  session.set_output_as_file('out/reset-2.pdf')
  session.resource('test.html') do |out|
    copy_stream(File.open('data/test.html'), out)
  end
  session.transcode_server('test.html')
  
  # 同じ文書を変換
  session.set_output_as_file('out/reset-3.pdf')
  session.transcode_server('test.html')
  
  # リセットして変換
  session.reset
  session.set_output_as_file('out/reset-4.pdf')
  session.transcode_server('test.html')
  
  # 再度変換
  session.set_output_as_file('out/reset-5.pdf')
  session.transcode('test.html') do |out|
    copy_stream(File.open('data/test.html'), out)
  end
end
