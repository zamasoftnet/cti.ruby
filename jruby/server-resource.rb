#!/usr/bin/jruby

include Java 
require 'cti-driver.jar'
include_class Java::jp.cssj.cti2.CTIDriverManager
include_class Java::jp.cssj.cti2.CTISession
include_class Java::jp.cssj.cti2.helpers.CTIMessageHelper
include_class Java::jp.cssj.cti2.helpers.CTISessionHelper
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
	
	# ハイパーリンクとブックマークを作成する
	session.property('output.pdf.hyperlinks', 'true')
	session.property('output.pdf.bookmarks', 'true')

	# http://copper-pdf.com/以下にあるリソースへのアクセスを許可する
	session.property('input.include', 'http://copper-pdf.com/**')

	# ウェブページを変換
	session.transcode(URI.create('http://copper-pdf.com/'))
ensure
	# セッションの終了
	session.close
end
