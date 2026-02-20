require 'tempfile'

module CTI
=begin rdoc
このモジュールのクラスは、１つの出力結果を構築するためのものです。
=end
  module Builder
    class Fragment
      def initialize(id)
        @id = id
        @prev = nil
        @nxt = nil
        @length = 0
        @buffer = ''
      end

      def id
        @id
      end

      def prev=(prev)
        @prev = prev
      end

      def prev
        @prev
      end

      def nxt=(nxt)
        @nxt = nxt
      end

      def nxt
        @nxt
      end

=begin
フラグメントにデータを書き込みます。

tempFile:: 一時ファイル
onMemory:: メモリ上に置かれたデータの合計サイズ
segment:: セグメント番号シーケンス
bytes:: データ

戻り値:: 書き込んだバイト数
=end

      def write(tempFile, onMemory, segment, bytes)
        len = bytes.bytesize
        if (!@segments &&
        @length + len <= CTIP2::FRG_MEM_SIZE &&
        onMemory + len <= CTIP2::ON_MEMORY)
          @buffer += bytes
          onMemory += len
        else
          if @buffer
            segment, wlen = raf_write(tempFile, segment, @buffer)
            onMemory -= wlen
            @buffer = nil
          end
          segment, len = raf_write(tempFile, segment, bytes)
        end
        @length += len
        return onMemory, segment, len
      end

=begin
フラグメントの内容を吐き出して、フラグメントを破棄します。

tempFile:: 一時ファイル
out:: 出力先ストリーム( IO )
=end

      def flush(tempFile, out)
        unless @segments
          out.write(@buffer)
          @buffer = nil
        else
          segcount = @segments.size
          for seg in @segments
            tempFile.pos = seg * CTIP2::SEGMENT_SIZE
            buff = tempFile.read(seg == @segments.last ? @segLen : CTIP2::SEGMENT_SIZE)
            out.write(buff)
          end
        end
      end

      private
=begin
一時ファイルに書き込みます。

tempFile:: 一時ファイル
segment:: セグメント番号シーケンス
bytes:: データ

戻り値:: 書き込んだバイト数
=end

      def raf_write(tempFile, segment, bytes)
        unless @segments
          @segments = [segment]
          segment += 1
          @segLen = 0
        end
        written = 0
        while (len = bytes.bytesize) > 0
          if @segLen == CTIP2::SEGMENT_SIZE
            @segments << segment
            segment += 1
            @segLen = 0
          end
          seg = @segments.last
          wlen = [len, CTIP2::SEGMENT_SIZE - @segLen].min
          wpos = seg * CTIP2::SEGMENT_SIZE + @segLen
          tempFile.pos = wpos
          data = bytes.slice!(0, wlen)
          tempFile.write(data)
          @segLen += wlen
          written += wlen
        end
        return segment, written
      end
    end
=begin rdoc
Version::   $Id: StreamBuilder.rb 902 2013-04-23 05:07:04Z miyabe $

ストリームに対して結果を構築するオブジェクトです。
=end

    class StreamBuilder
=begin rdoc
結果構築オブジェクトを作成します。

out:: 出力先ストリーム
&finish:: 結果を実際に出力する前に呼び出されるブロック。引数として結果のバイト数が渡されます

例:
    SingleResult.new(StreamBuilder.new($stdout) do |length|
      print "Content-Length: #{length}\r\n\r\n"
    end) do |opts|
      print "Content-Type: #{opts['mime_type']}\r\n"
    end
=end
      def initialize(out, &finish)
        @tempFile = Tempfile.open(['cti', '.tmp'])
        @out = out
        @finish = finish
        @frgs = []
        @first = nil
        @last = nil
        @onMemory = 0
        @length = 0
        @segment = 0
      end

      def add_block
        id = @frgs.size
        frg = Fragment.new(id)
        @frgs[id] = frg
        unless @first
          @first = frg
        else
          @last.nxt = frg
          frg.prev = @last
        end
        @last = frg
      end

      def insert_block_before(anchor_id)
        id = @frgs.size
        anchor = @frgs[anchor_id]
        frg = Fragment.new(id)
        @frgs[id] = frg
        frg.prev = anchor.prev
        frg.nxt = anchor
        anchor.prev.nxt = frg
        anchor.prev = frg
        @first = frg if @first.id == anchor.id
      end

      def write(id, data)
        frg = @frgs[id]
        @onMemory, @segment, len = frg.write(@tempFile, @onMemory, @segment, data)
        @length += len
      end

      def close_block(id)
      end

      def serial_write(data)
        @out.write(data)
      end

      def finish
        begin
          @finish.call(@length) if @finish
          frg = @first
          while frg
            frg.flush(@tempFile, @out)
            frg = frg.nxt
          end
        ensure
          @tempFile.close
        end
      end

      def dispose
      end
    end
  end
end