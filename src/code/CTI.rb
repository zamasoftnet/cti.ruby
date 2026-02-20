require File.expand_path('CTI/Driver', File.dirname(__FILE__))
=begin rdoc
:main:CTI
= CTI driver for Ruby
Version::   $Id: CTI.rb 1617 2022-01-24 07:26:44Z miyabe $

RubyでCopper PDF 2.1以降にアクセスするためのドライバです。
以下のドキュメントを参照してください。

http://dl.cssj.jp/docs/copper/3.1/html/3424_ctip2_ruby.html
=end
module CTI
  module_function
=begin rdoc
指定されたURIに接続するためのドライバを返します。
 
uri:: 接続先アドレス

返り値:: CTI::Driver オブジェクト
=end
  def get_driver(uri)
    return Driver.new
  end

=begin rdoc
指定されたURIに接続し、セッションを返します。
 
uri:: 接続先アドレス
options:: 接続オプション

返り値:: CTI::Session オブジェクト
=end
  def get_session(uri, options = {}, &block)
    get_driver(uri).get_session(uri, options, &block)
  end

=begin rdoc
指定された inp から out へコピーします。コピーしたバイト数を返します。
inp には read メソッド、out には write メソッドが必要です。
仕様が変わってしまったRubyのFileUtils::copy_stream, IO::copy_streamに代わるものです。

inp:: 転送元
out:: 転送先

=end
  def copy_stream(inp, out)
    read = 0;
    while buff = inp.read(16 * 1024)
      read += buff.length
	  out.write(buff)
    end
  end
end