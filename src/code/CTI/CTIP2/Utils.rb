module CTI
  module CTIP2
=begin rdoc
32ビット数値をビッグインディアンで書き出します。

a:: 数値
戻り値:: 書き込んだバイト数
=end
    def write_int(a)
      self.write([a].pack('N'))
    end

=begin rdoc
64ビット数値をビッグインディアンで書き出します。

a:: 数値
戻り値:: 書き込んだバイト数
=end

    def write_long(a)
      self.write([a >> 32, a & 0xFFFFFFFF].pack('NN'))
    end

=begin rdoc
8ビット数値を書き出します。

a:: 数値
戻り値:: 書き込んだバイト数
=end

    def write_byte(b)
      self.write([b].pack('C'))
    end

=begin rdoc
バイト数を16ビットビッグインディアンで書き出した後、バイト列を書き出します。

b:: バイト列
戻り値:: 書き込んだバイト数
=end

    def write_bytes(b)
      self.write([b.bytesize].pack('n'))
      self.write(b)
    end

=begin rdoc
16ビットビッグインディアン数値を読み込みます。

戻り値:: 数値、エラーであればfalse
=end

    def read_short
      b = self.read(2)
      a = b.unpack('n')
      return a[0]
    end

=begin rdoc
32ビットビッグインディアン数値を読み込みます。

戻り値:: 数値、エラーであればfalse
=end

    def read_int
      b = self.read(4)
      a = b.unpack('N')
      return a[0]
    end

=begin rdoc
64ビットビッグインディアン数値を読み込みます。

戻り値:: 数値、エラーであればfalse
=end

    def read_long
      b = self.read(8)
      a = b.unpack('NN')
      h = a[0]
      l = a[1]
      if h >> 31 != 0  then
        h ^= 0xFFFFFFFF
        l ^= 0xFFFFFFFF
        b = (h << 32) | l
        b = -(b + 1)
      else
        b = (h << 32) | l
      end
      return b;
    end

=begin rdoc
8ビット数値を読み込みます。

戻り値:: 数値、エラーであればfalse
=end

    def read_byte
      b = self.read(1)
      b = b.unpack('C')
      return b[0]
    end

=begin rdoc
16ビットビッグインディアン数値を読み込み、そのバイト数だけバイト列を読み込みます。

戻り値:: バイト列、エラーであればfalse
=end

    def read_bytes
      b = self.read(2)
      a = b.unpack('n')
      len = a[0]
      b = self.read(len);
      return b;
    end
  end
end