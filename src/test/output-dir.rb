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
  
  #JPEG出力
  session.property('output.type', 'image/jpeg')
    
  #ファイル出力
  dir = 'out/output-dir'
  Dir::mkdir(dir, 0777) unless File.exist?(dir)
  session.set_output_as_directory(dir, '', '.jpg')

  # リソースの送信
  session.resource('test.css') do |out|
    copy_stream(File.open('data/test.css'), out)
  end

  # 文書の送信
  session.transcode do |out|
    copy_stream(File.open('data/test.html'), out)
  end
end
