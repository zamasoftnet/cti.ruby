#!/usr/bin/ruby
require '../code/CTI'
include CTI
require 'erb'

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
  session.set_output_as_file('out/erb.pdf')

  # テンプレートを変換
  session.transcode do |out|
    begin
      $stdout = out
      ERB.new(DATA.read).run
    ensure
      $stdout = STDOUT
    end
  end
end
__END__
<html>
  <head>
    <title>ERB</title>
  </head>
  <body>
  <p>Hello ERB</p>
  <p>ただいまの時刻は <%= Time.now %></p>
  </body>
</html>