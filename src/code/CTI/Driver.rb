require File.expand_path('Session', File.dirname(__FILE__))
require 'socket'

module CTI
=begin rdoc
Version::   $Id: Driver.rb 902 2013-04-23 05:07:04Z miyabe $
  
ドライバクラスです。通常は直接使用する必要はありません。
代わりに CTI#get_session メソッドを使用してください。
=end
  class Driver
    public
=begin rdoc
指定されたURIに接続し、セッションを返します。

uri:: 接続先アドレス
options:: 接続オプション

返り値:: CTI::Session オブジェクト
=end
    def get_session(uri, options = {}, &block)
      # uriの解析
      host = 'localhost'
      port = 8099
      ssl = false
      if /^ctips:\/\/([^:\/]+):([0-9]+)\/?$/ =~ uri then
        ssl = true
        host = $1
        port = $2.to_i
      elsif /^ctips:\/\/([^:\/]+)\/?$/ =~ uri then
        ssl = true
        host = $1
      elsif /^ctip:\/\/([^:\/]+):([0-9]+)\/?$/ =~ uri then
        host = $1
        port = $2.to_i
      elsif /^ctip:\/\/([^:\/]+)\/?$/ =~ uri then
        host = $1
      end
      
      io = TCPSocket.open(host, port)
      if ssl
        # TLSを使う場合
        #
        # **証明書を検証し、SNIを送る。**素の SSLSocket.new(io) は
        # 検証を一切しない(VERIFY_NONE)ので、TLSにしても相手が誰かを
        # 確かめないまま話すことになる。SNIも送らないため、名前で証明書を
        # 選ぶ中継(Traefik など)からは既定の自己署名証明書が返ってくる。
        require 'openssl'
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.set_params  # 既定のCAと VERIFY_PEER を入れる
        io = OpenSSL::SSL::SSLSocket.new(io, ctx)
        io.hostname = host  # SNI
        io.sync_close = true
        io.connect
        io.post_connection_check(host)  # 証明書の名前がホストと一致するか
      end
      session = Session.new(io, options)
      if block
        # ブロック実行
        begin
          block.call(session)
        ensure
          session.close()
        end
      else
        return session
      end
    end
  end
end