require File.expand_path('CTIP2/CTIP2', File.dirname(__FILE__))
require File.expand_path('Builder/FileBuilder', File.dirname(__FILE__))
require File.expand_path('Results/SingleResult', File.dirname(__FILE__))
require File.expand_path('Builder/StreamBuilder', File.dirname(__FILE__))
require File.expand_path('Results/DirectoryResults', File.dirname(__FILE__))
require "io/nonblock"

include CTI::Builder, CTI::Results

module CTI
=begin rdoc
Version::   $Id: Session.rb 1617 2022-01-24 07:26:44Z miyabe $

ドキュメント変換サーバーへの接続オブジェクトです。
=end
  class Session
=begin rdoc
セッションを構築します。このメソッドを直接呼び出す必要はありません。

CTI#get_session メソッドを使用してください。

io:: サーバーと通信するための IO オブジェクト
opts:: 接続オプション(ハッシュ型で、'encoding', 'user', 'password'というキーで文字コード、ユーザー名、パスワードを設定することができます。)
    
返り値:: サーバー情報のデータ文字列(XML)
=end
    def initialize(io, opts)
      self.reset
      @io = io

      io.extend CTIP2

      opts.default = 'UTF-8'
      @encoding = opts['encoding']
      opts.default = ''
      user = opts['user']
      password = opts['password']

      io.cti_connect(@encoding)
      data = "PLAIN: #{user} #{password}\n"
      io.write(data)
      res = io.read(4)
      raise "Authentication failure." if res != "OK \n"
    end

=begin rdoc
サーバー情報を返します。
詳細は{オンラインのドキュメント}[http://sourceforge.jp/projects/copper/wiki/CTIP2.0%E3%81%AE%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E6%83%85%E5%A0%B1]をご覧下さい。

uri:: サーバー情報のURI

返り値:: サーバー情報のデータ文字列(XML)
=end

    def get_server_info(uri)
      @io.req_server_info(uri)
      data = ''
      while true
        res = @io.res_next
        break if res['type'] == CTIP2::RES_EOF
        data += res['bytes']
      end
      return data
    end

=begin rdoc
変換結果の出力先を指定します。

CTI::Session#transcode および CTI::Session#transcode_server の前に呼び出してください。
この関数を呼び出さないデフォルトの状態では、出力先は標準出力( STDOUT )になります。

また、デフォルトの状態では、自動的にContent-Type, Content-Lengthヘッダが送出されます。

results:: 出力先の CTI::Results オブジェクト
=end

    def set_results(results)
      raise "set_results: Main content is already sent." if @state >= 2
      @results = results
    end

=begin rdoc
変換結果の出力先ファイル名を指定します。

CTI::Session#set_results　の簡易版です。
こちらは、１つだけ結果を出力するファイル名を直接設定することができます。

file:: 出力先ファイル名
=end

    def set_output_as_file(file)
      set_results(SingleResult.new(FileBuilder.new(file)))
    end

=begin rdoc
変換結果の出力先ディレクトリ名を指定します。

CTI::Session#set_results の簡易版です。
こちらは、複数の結果をファイルとして出力するディレクトリ名を直接設定することができます。
ファイル名は prefix ページ番号 suffix をつなげたものです。

dir:: 出力先ディレクトリ名
prefix:: 出力するファイルの名前の前に付ける文字列
suffix:: 出力するファイルの名前の後に付ける文字列
=end

    def set_output_as_directory(dir, prefix = '', suffix = '')
      set_results(DirectoryResults.new(dir, prefix, suffix))
    end

=begin rdoc
変換結果の出力先リソースを指定します。

CTI::Session#set_results の簡易版です。
こちらは、１つだけの結果出力先を直接設定することができます。

out:: 出力先 IO オブジェクト
=end

    def set_output_as_stream(out)
      set_results(SingleResult.new(StreamBuilder.new(out)))
    end

=begin rdoc
エラーメッセージ受信のためのブロックを設定します。

CTI::Session#transcode および CTI::Session#transcode_server の前に呼び出してください。
ブロックの引数は、エラーコード(int)、メッセージ(string)、付属データ(array)です。

&messageFunc:: ブロック

例:
    session.receive_message do |code, message, args|
      printf("%X %s\n", code, message)
      p args
    end
=end

    def receive_message(&messageFunc)
      raise "receive_message: Main content is already sent." if @state >= 2
      @messageFunc = messageFunc;
    end

=begin rdoc
進行状況受信のためのブロックを設定します。

CTI::Session#transcode および CTI::Session#transcode_server の前に呼び出してください。
ブロックの引数は、全体のバイト数(int)、読み込み済みバイト数(int)です。

&progressFunc:: ブロック

例:
    session.receive_progress do |length, read|
      puts "#{read} / #{length}"
    end
=end

    def receive_progress(&progressFunc)
      raise "receive_progress: Main content is already sent." if @state >= 2
      @progressFunc = progressFunc;
    end

=begin rdoc
リソース解決のためのブロックを設定します。

CTI::Session#transcode および CTI::Session#transcode_server の前に呼び出してください。
ブロックの引数は、URI(string)、リソース出力クラス( CTI::Resource )です。

&resolverFunc:: ブロック

URIに対応するリソースが見つかった場合、 CTI::Resource#found メソッドを呼び出してください。
foundの呼び出しがない場合、リソースは見つからなかったものと扱われます。

例:
    session.resolver do |uri, r|
      if File.exist?(uri)
        r.found do |out|
          copy_stream(File.open(uri), out)
        end
      end
    end
=end

    def resolver(&resolverFunc)
      raise "resolver: Main content is already sent." if @state >= 2
      @resolverFunc = resolverFunc;
      @io.req_client_resource(resolverFunc ? 1 : 0)
    end

=begin rdoc
複数の結果を結合するモードを切り替えます。
モードが有効な場合、 CTI::Session#join の呼び出しで複数の結果を結合して返します。

CTI::Session#transcode および CTI::Session#transcode_server の前に呼び出してください。

continuous:: 有効にするにはtrue
=end

    def set_continuous(continuous)
      raise "set_continuous: Main content is already sent." if @state >= 2
      @io.req_continuous(continuous ? 1 : 0)
    end

=begin rdoc
プロパティを設定します。

セッションを作成した直後に呼び出してください。
利用可能なプロパティの一覧は{資料集}[http://dl.cssj.jp/docs/copper/3.0/html/5100_io-properties.html]を参照してください。

name:: 名前
value:: 値
=end

    def property(name, value)
      raise "property: Main content is already sent." if @state >= 2
      @io.req_property(name, value)
    end

=begin rdoc
リソース送信処理を行います。
CTI::Session#transcode および CTI::Session#transcode_server の前に呼び出してください。

uri:: 仮想URI
opts:: リソースオプション(ハッシュ型で、'mime_type', 'encoding', 'length'というキーでデータ型、文字コード、長さを設定することができます。)
&block:: リソースを送信するためのブロックで、引数としてリソースの出力先ストリームが渡されます。

戻り値:: &blockがない場合はリソースの出力先ストリームが返されます。

例:
    session.resource('test.css', {'mime_type' => 'test/css'}) do |out|
      copy_stream(File.open('data/test.css'), out)
    end
=end

    def resource(uri, opts = {}, &block)
      raise "resource: Main content is already sent." if @state >= 2
      opts.default = 'text/css'
      mime_type = opts['mime_type']
      opts.default = ''
      encoding = opts['encoding']
      opts.default = -1
      length = opts['length']
      @io.req_resource(uri, mime_type, encoding, length)

      out = ResourceOut.new(@io)
      if block
        begin
          block.call(out)
        ensure
          out.close
        end
      else
        return out
      end
    end

=begin rdoc
変換対象の文書リソースを送信し、変換処理を行います。

uri:: 仮想URI
opts:: リソースオプション(ハッシュ型で、'mime_type', 'encoding', 'length'というキーでデータ型、文字コード、長さを設定することができます。)
&block:: リソースを送信するためのブロックで、引数としてリソースの出力先ストリームが渡されます。

戻り値:: &blockがない場合はリソースの出力先ストリームが返されます。

例:
    session.transcode('.', {'mime_type' => 'text/html'}) do |out|
      copy_stream(File.open('data/test.html'), out)
    end
=end

    def transcode(uri = '.', opts = {}, &block)
      raise "transcode: Main content is already sent." if @state >= 2
      opts.default = 'text/css'
      mime_type = opts['mime_type']
      opts.default = ''
      encoding = opts['encoding']
      opts.default = -1
      length = opts['length']
      state = 2
      @io.req_start_main(uri, mime_type, encoding, length)

      out = MainOut.new(@io, self)
      if block
        begin
          block.call(out)
        ensure
          out.close
        end
      else
        return out
      end
    end

=begin rdoc
サーバー側リソースを変換します。

uri:: URI
=end

    def transcode_server(uri)
      raise "transcode_server: Main content is already sent." if @state >= 2
      @io.req_server_main(uri)
      @state = 2
      while build_next
      end
    end
    
=begin rdoc
<b>DEPRECATED:</b>　{#transcode_server} を使って下さい。
    
サーバー側リソースを変換します。

uri:: URI
=end
    def transcodeServer(uri)
      transcode_server(uri)
    end

=begin rdoc
変換処理の中断を要求します。

mode:: 中断モード 0=生成済みのデータを出力して中断, 1=即時中断
=end

    def abort(mode)
      raise "abort: The session is already closed."  if @state >= 3
      @io.req_abort(mode)
    end

=begin rdoc
全ての状態をリセットします。
=end

    def reset
      raise "reset: The session is already closed."  if @state && @state >= 3
      if @io
        @io.req_reset
      end
      @progressFunc = nil
      @messageFunc = nil
      @resolverFunc = nil
      @results = SingleResult.new(StreamBuilder.new(STDOUT) do |length|
        print "Content-Length: #{length}\r\n\r\n"
      end) do |opts|
        print "Content-Type: #{opts['mime_type']}\r\n"
      end
      @state = 1
    end

=begin rdoc
結果を結合します。

先に CTI::Session#set_continuous を呼び出しておく必要があります。
=end

    def join
      raise "join: The session is already closed."  if @state >= 3
      @io.req_join
      @state = 2
      while build_next
      end
    end

=begin rdoc
セッションを閉じます。
=end

    def close
      raise "close: The session is already closed."  if @state >= 3
      @io.req_close;
      @state = 3
    end

    def build_next
      res = @io.res_next
      case res['type']
      when CTIP2::RES_START_DATA
        if @builder
          @builder.finish
          @builder.dispose
        end
        @builder = @results.next_builder(res)

      when CTIP2::RES_BLOCK_DATA
        @builder.write(res['block_id'], res['bytes'])

      when CTIP2::RES_ADD_BLOCK
        @builder.add_block

      when CTIP2::RES_INSERT_BLOCK
        @builder.insert_block_before(res['block_id'])

      when CTIP2::RES_CLOSE_BLOCK
        @builder.close_block(res['block_id'])

      when CTIP2::RES_DATA
        @builder.serial_write(res['bytes'])

      when CTIP2::RES_MESSAGE
        @messageFunc.call(res['code'], res['message'], res['args']) if @messageFunc

      when CTIP2::RES_MAIN_LENGTH
        @mainLength = res['length']
        @progressFunc.call(@mainLength, @mainRead) if @progressFunc

      when CTIP2::RES_MAIN_READ
        @mainRead = res['length']
        @progressFunc.call(@mainLength, @mainRead) if @progressFunc

      when CTIP2::RES_RESOURCE_REQUEST
        uri = res['uri']
        r = Resource.new(@io, uri)
        @resolverFunc.call(uri, r) if @resolverFunc
        r.finish
        @io.req_missing_resource(uri) if r.missing

      when CTIP2::RES_ABORT
        if @builder
          @builder.finish if res['mode'] == 0
          @builder.dispose
          @builder = nil
        end
        @mainLength = nil
        @mainRead = nil
        @state = 1
        return false

      when CTIP2::RES_EOF
        @builder.finish
        @builder.dispose
        @builder = nil
        @mainLength = nil
        @mainRead = nil
        @state = 1
        return false

      when CTIP2::RES_NEXT
        @state = 1
        return false
      end
      return true
    end
  end

  protected

  class ResourceOut
    def initialize(io)
      @io = io
      @closed = false
    end

    def write(str)
      e = str.encoding;
      str.force_encoding(Encoding::ASCII_8BIT)
      while str.bytesize > 0
        data = str.slice!(0, CTIP2::CTI_BUFFER_SIZE)
        @io.req_write(data)
      end
      str.force_encoding(e)
    end

    def close
      unless @closed
        @io.req_eof
        @cloded = true
      end
    end
  end

  class MainOut
    def initialize(io, session)
      @io = io
      @session = session
    end

    def write(str)
      e = str.encoding;
      str.force_encoding(Encoding::ASCII_8BIT)
      bio = @io.respond_to?('write_nonblock')
      while str.bytesize > 0
        data = str.slice!(0, CTIP2::CTI_BUFFER_SIZE)
        packet = [data.bytesize + 1, CTIP2::REQ_DATA].pack('NC') + data
        while packet.bytesize > 0
          rs, ws = IO::select([@io], [@io])
          if packet.bytesize > 0 && ws[0]
            if bio
              len = @io.write_nonblock(packet)
              @io.nonblock = false
            else
              len = @io.write(packet)
            end
            packet.slice!(0, len)
          end
          if rs[0]
            @session.build_next
          end
        end
      end
      str.force_encoding(e)
    end

    def close
      @io.req_eof
      while @session.build_next
      end
    end
  end

=begin rdoc
CTI::Session#resolver により設定したブロック内で、サーバーにリソースを送るためのオブジェクトです。
=end

  class Resource
    def initialize(io, uri)
      @io = io
      @uri = uri
      @missing = true
    end

    def missing
      @missing
    end
=begin rdoc
サーバーから要求されたリソースが見つかった場合の処理をします。

opts:: リソースオプション(ハッシュ型で、'mime_type', 'encoding', 'length'というキーでデータ型、文字コード、長さを設定することができます。)
&block:: リソースを送信するためのブロックで、引数としてリソースの出力先ストリームが渡されます。

戻り値:: &blockがない場合はリソースの出力先ストリームが返されます。

例:
CTI::Session#resolver を参照してください。
=end

    def found(opts = {}, &block)
      opts.default = 'text/css'
      mime_type = opts['mime_type']
      opts.default = ''
      encoding = opts['encoding']
      opts.default = -1
      length = opts['length']
      @io.req_resource(@uri, mime_type, encoding, length)
      @missing = false;
      @out = ResourceOut.new(@io)
      if block
        begin
          block.call(@out)
        ensure
          @out.close
          @out = nil
        end
      else
        return @out
      end
    end

    def finish
      @out.close if @out
    end
  end
end