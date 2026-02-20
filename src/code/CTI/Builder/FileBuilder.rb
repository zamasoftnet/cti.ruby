require File.expand_path('StreamBuilder', File.dirname(__FILE__))

module CTI
  module Builder
=begin rdoc
Version::   $Id: FileBuilder.rb 902 2013-04-23 05:07:04Z miyabe $

ファイルに対して結果を構築するオブジェクトです。
=end
  class FileBuilder < StreamBuilder
=begin rdoc
結果構築オブジェクトを作成します。

file:: 結果ファイル
=end
      def initialize(file)
        super(nil)
        @file = file
      end

      def serial_write(data)
        @out = File.open(@file, 'w') unless @out
        @out.write(data)
      end

      def finish
        unless @out
          @out = File.open(@file, 'w')
          super
        end
        @out.close
        @out = nil
      end
    end
  end
end