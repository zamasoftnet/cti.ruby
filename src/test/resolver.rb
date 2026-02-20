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
  session.set_output_as_file('out/resolver.pdf')

  # リソースの送信
  session.resolver do |uri, r|
    if File.exist?(uri)
      r.found do |out|
        copy_stream(File.open(uri), out)
      end
    end
  end

  # 文書の送信
  session.transcode('data/test.html') do |out|
    copy_stream(File.open('data/test.html'), out)
  end
end
