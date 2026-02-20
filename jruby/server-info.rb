#!/usr/bin/jruby

include Java
#jarのパスは環境に合わせてください
require 'cti-driver.jar'

include_class Java::jp.cssj.cti2.CTIDriverManager
include_class Java::jp.cssj.cti2.CTISession
include_class Java::java.io.InputStream
include_class Java::java.net.URI

# セッションの開始
uri = URI.create('ctip://localhost:8099/')
session = CTIDriverManager.getSession(uri, 'user', 'kappa')
begin

  #バージョン情報
  uri = URI.create('http://www.cssj.jp/ns/ctip/version')
  inp = session.getServerInfo(uri).to_io
  print inp.read
  inp.close

  #サポートする出力形式
  uri = URI.create('http://www.cssj.jp/ns/ctip/output-types')
  inp = session.getServerInfo(uri).to_io
  print inp.read
  inp.close

ensure
  # セッションの終了
  session.close
end