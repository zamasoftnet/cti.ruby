require File.expand_path('Utils', File.dirname(__FILE__))

module CTI
=begin rdoc
Version::   $Id: CTIP2.rb 902 2013-04-23 05:07:04Z miyabe $

通信プロトコルに関連する各操作です。

このモジュールに所属するメソッドは、 IO に対するものです。
=end
  module CTIP2
    REQ_PROPERTY = 0x01
    REQ_START_MAIN = 0x02
    REQ_SERVER_MAIN = 0x03
    REQ_CLIENT_RESOURCE = 0x04
    REQ_CONTINUOUS = 0x05
    REQ_DATA = 0x11
    REQ_START_RESOURCE = 0x21
    REQ_MISSING_RESOURCE = 0x22
    REQ_EOF = 0x31
    REQ_ABORT = 0x32
    REQ_JOIN = 0x33
    REQ_RESET = 0x41
    REQ_CLOSE = 0x42
    REQ_SERVER_INFO = 0x51

    RES_START_DATA = 0x01
    RES_BLOCK_DATA = 0x11
    RES_ADD_BLOCK = 0x12
    RES_INSERT_BLOCK = 0x13
    RES_MESSAGE = 0x14
    RES_MAIN_LENGTH = 0x15
    RES_MAIN_READ = 0x16
    RES_DATA = 0x17
    RES_CLOSE_BLOCK = 0x18
    RES_RESOURCE_REQUEST = 0x21
    RES_EOF = 0x31
    RES_ABORT = 0x32
    RES_NEXT = 0x33
    
=begin rdoc
パケットの送信に使うバッファのサイズです。
=end
    CTI_BUFFER_SIZE = 1024

=begin rdoc
メモリ上のフラグメントの最大サイズです。

フラグメントがこの大きさを超えるとディスクに書き込みます。
=end
    FRG_MEM_SIZE = 256

=begin rdoc
メモリ上に置かれるデータの最大サイズです。

メモリ上のデータがこのサイズを超えると、
FRG_MEM_SIZEとは無関係にディスクに書き込まれます。
=end
    ON_MEMORY = 1024 * 1024

=begin rdoc
一時ファイルのセグメントサイズです。
=end
    SEGMENT_SIZE = 8192

=begin rdoc
セッションを開始します。

encoding:: 通信に用いるエンコーディング
=end
    def cti_connect(encoding)
      self.write("CTIP/2.0 #{encoding}\n")
    end

=begin rdoc
サーバー情報を要求します。

uri:: URI
=end

    def req_server_info(uri)
      payload = 1 + 2 + uri.bytesize
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_SERVER_INFO)
      self.write_bytes(uri)
      self.flush
    end

=begin rdoc
サーバーからクライアントのリソースを要求するモードを切り替えます。

mode:: 0=off, 1=on
=end

    def req_client_resource(mode)
      payload = 2
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_CLIENT_RESOURCE)
      self.write_byte(mode)
      self.flush
    end

=begin rdoc
複数の結果を結合するモードを切り替えます。

mode:: 0=off, 1=on
=end

    def req_continuous(mode)
      payload = 2
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_CONTINUOUS)
      self.write_byte(mode)
      self.flush
    end

=begin rdoc
リソースの不存在を通知します。

uri:: URI
=end

    def req_missing_resource(uri)
      payload = 1 + 2 + uri.bytesize
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_MISSING_RESOURCE)
      self.write_bytes(uri)
      self.flush
    end

=begin rdoc
状態のリセットを要求します。
=end

    def req_reset
      payload = 1
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_RESET)
      self.flush
    end

=begin rdoc
変換処理の中断を要求します。

mode::  0=生成済みのデータを出力して中断, 1=即時中断
=end

    def req_abort(mode)
      payload = 2
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_ABORT)
      self.write_byte(mode)
      self.flush
    end

=begin rdoc
変換結果を結合します。
=end

    def req_join
      payload = 1
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_JOIN)
      self.flush
    end

=begin rdoc
終了を通知します。
=end

    def req_eof
      payload = 1
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_EOF)
      self.flush
    end

=begin rdoc
プロパティを送ります。

name:: 名前
value:: 値
=end

    def req_property(name, value)
      payload = name.bytesize + value.bytesize + 5
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_PROPERTY)
      self.write_bytes(name)
      self.write_bytes(value)
      self.flush
    end

=begin rdoc
サーバー側データの変換を要求します。

uri:: URI
=end

    def req_server_main(uri)
      payload = uri.bytesize + 3
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_SERVER_MAIN)
      self.write_bytes(uri)
      self.flush
    end

=begin rdoc
リソースの開始を通知します。

uri:: URI
mime_type:: MIME型
encoding:: エンコーディング
length:: 長さ
=end

    def req_resource(uri, mime_type = 'text/css', encoding = '', length = -1)
      payload = uri.bytesize + mime_type.bytesize + encoding.bytesize + 7 + 8
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_START_RESOURCE)
      self.write_bytes(uri)
      self.write_bytes(mime_type)
      self.write_bytes(encoding)
      self.write_long(length)
      self.flush
    end

=begin rdoc
本体の開始を通知します。

uri:: URI
mime_type:: MIME型
encoding:: エンコーディング
length:: 長さ
=end

    def req_start_main(uri, mime_type = 'text/html', encoding = '', length = -1)
      payload = uri.bytesize + mime_type.bytesize + encoding.bytesize + 7 + 8
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_START_MAIN)
      self.write_bytes(uri)
      self.write_bytes(mime_type)
      self.write_bytes(encoding)
      self.write_long(length)
      self.flush
    end

=begin rdoc
データを送ります。

b:: データ
=end

    def req_write(b)
      payload = b.bytesize + 1
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_DATA)
      self.write(b)
      self.flush
    end

=begin rdoc
通信を終了します。
=end

    def req_close
      payload = 1
      self.write_int(payload)
      self.write_byte(CTIP2::REQ_CLOSE)
      self.flush
    end

=begin rdoc
次のレスポンスを取得します。

結果ハッシュには次のデータが含まれます。

- 'type' レスポンスタイプ
- 'anchorId' 挿入する場所の直後のフラグメントID
- 'level' エラーレベル
- 'error' エラーメッセージ
- 'id' 断片ID
- 'progress' 処理済バイト数
- 'bytes' データのバイト列

戻り値:: レスポンス
=end

    def res_next
      payload = self.read_int
      type = self.read_byte

      case type
      when CTIP2::RES_ADD_BLOCK, CTIP2::RES_EOF, CTIP2::RES_NEXT
        return {
          'type' => type,
        }

      when CTIP2::RES_START_DATA
        uri = self.read_bytes
        mime_type = self.read_bytes
        encoding = self.read_bytes
        length = self.read_long
        return {
          'type' => type,
          'uri' => uri,
          'mime_type' => mime_type,
          'encoding' => encoding,
          'length' => length
        }

      when CTIP2::RES_MAIN_LENGTH, CTIP2::RES_MAIN_READ
        length = self.read_long
        return {
          'type' => type,
          'length' => length
        }

      when CTIP2::RES_INSERT_BLOCK, CTIP2::RES_CLOSE_BLOCK
        block_id = self.read_int
        return {
          'type' => type,
          'block_id' => block_id
        }

      when CTIP2::RES_MESSAGE
        code = self.read_short
        payload -= 1 + 2
        message = self.read_bytes
        payload -= 2 + message.bytesize
        args = []
        while payload > 0
          arg = self.read_bytes
          payload -= 2 + arg.bytesize
          args << arg
        end
        return {
          'type' => type,
          'code' => code,
          'message' => message,
          'args' => args
        }

      when CTIP2::RES_BLOCK_DATA
        length = payload - 5
        block_id = self.read_int
        bytes = self.read(length)
        return {
          'type' => type,
          'block_id' => block_id,
          'bytes' => bytes,
          'length' => length
        }

      when CTIP2::RES_DATA
        length = payload - 1
        bytes = self.read(length)
        return {
          'type' => type,
          'bytes' => bytes,
          'length' => length
        }

      when CTIP2::RES_RESOURCE_REQUEST
        uri = self.read_bytes
        return {
          'type' => type,
          'uri' => uri
        }

      when CTIP2::RES_ABORT
        mode = self.read_byte
        code = self.read_short
        payload -= 1 + 1 + 2
        message = self.read_bytes
        payload -= 2 + message.bytesize
        args = []
        while payload > 0
          arg = self.read_bytes
          payload -= 2 + arg.bytesize
          args << arg
        end
        return {
          'type' => type,
          'mode' => mode,
          'code' => code,
          'message' => message,
          'args' => args
        }

      else
        raise "Bad response type:#{type}"
      end
    end
  end
end