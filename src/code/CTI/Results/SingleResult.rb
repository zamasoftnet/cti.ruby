require File.expand_path('../Builder/NullBuilder', File.dirname(__FILE__))

module CTI
=begin rdoc
このモジュールのクラスは、 CTI::Session#set_results に渡して結果を得るために使います。
=end
  module Results
=begin rdoc
Version::   $Id: SingleResult.rb 902 2013-04-23 05:07:04Z miyabe $

単一の結果を得るためのオブジェクトです。
=end
    class SingleResult
=begin rdoc
結果オブジェクトを作成します。

builder:: CTI::Builder オブジェクト
&block:: 結果が出力される直前に呼び出されるブロックです。引数にハッシュ型として結果に関する情報が渡されます。
ハッシュには'uri', 'mime_type', 'encoding', 'length'というキーでそれぞれURI, MIME型, 文字コード, 結果長さが格納されます。
ただし、'encoding', 'length'は必ずしも提供されません。
=end
      def initialize(builder, &block)
        @builder = builder
        @block = block
      end

      def next_builder(opts = {})
        return CTI::Builder::NullBuilder.new unless @builder
        @block.call(opts) if @block
        builder = @builder
        @builder = nil
        return builder
      end
    end
  end
end