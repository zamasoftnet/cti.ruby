require File.expand_path('../Builder/FileBuilder', File.dirname(__FILE__))

module CTI
  module Results
=begin rdoc
Version::   $Id: DirectoryResults.rb 902 2013-04-23 05:07:04Z miyabe $

ディレクトリに複数のファイルとして結果を得るためのオブジェクトです。
=end
    class DirectoryResults
=begin rdoc
結果オブジェクトを作成します。

dir:: 出力先ディレクトリ
prefix:: 結果ファイル名の先頭に付ける文字列
suffix:: 結果ファイル名の末尾に付ける文字列
=end
      def initialize(dir, prefix = '', suffix = '')
        @dir = dir
        @prefix = prefix
        @suffix = suffix
        @counter = 0
      end
    
      def next_builder(opts = {})
        @counter += 1
        return CTI::Builder::FileBuilder.new("#{@dir}/#{@prefix}#{@counter}#{@suffix}")
      end
    end
  end
end