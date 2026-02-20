#!/usr/bin/jruby

include Java 
#jarのパスは環境に合わせてください
require 'cti-driver.jar'
include_class Java::jp.cssj.cti2.CTIDriverManager
include_class Java::jp.cssj.cti2.CTISession
include_class Java::jp.cssj.cti2.helpers.CTIMessageHelper
include_class Java::jp.cssj.cti2.helpers.CTISessionHelper
include_class Java::jp.cssj.resolver.helpers.MetaSourceImpl
include_class Java::java.net.URI
include_class Java::java.lang.System

# セッションの開始
uri = URI.create('ctip://localhost:8099/')
session = CTIDriverManager.getSession(uri, 'user', 'kappa')
begin

	# ファイル出力
  file = java.io.File.new('test.pdf')
	CTISessionHelper.setResultFile(session, file)
	
	# エラーメッセージを標準エラー出力に表示する
	mh = CTIMessageHelper.createStreamMessageHandler(System.err)
	session.setMessageHandler(mh)
	
	# サーバーへの出力をJavaのOutputStreamからRubyのioに変換して取得
	ms = MetaSourceImpl.new(URI.create('.'), 'text/html', 'UTF-8');
	out = session.transcode(ms).to_io;
	begin
		out.puts <<DATA
<html>
<body>
JRubyからCopper PDFを使う。
</body>
</html>
DATA
	ensure
		# クローズを忘れないこと！
		out.close;
	end;
	
ensure
	# セッションの終了
	session.close
end
