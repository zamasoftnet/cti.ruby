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
  session.set_output_as_file('out/continuous.pdf')

  # リソースの送信
  session.resource('test.css') do |out|
    copy_stream(File.open('data/test.css'), out)
  end
  
  session.set_continuous(true)

  # 文書の送信
  session.transcode do |out|
    copy_stream(File.open('data/test.html'), out)
  end

  #リソースのアクセス許可
  session.property('input.include', 'http://copper-pdf.com/**')
    
  #文書の変換
  session.transcode_server('http://copper-pdf.com/')
  
  # 結合
  session.join
end
