module CTI
  module Builder
=begin rdoc
このオブジェクトは結果を構築しません。
=end
    class NullBuilder
      def add_block
      end
      
      def insert_block_before (anchor_id)
      end
      
      def write (id, data)
      end
      
      def close_block (id)
      end
      
      def serial_write (data)
      end
      
      def finish
      end
      
      def dispose
      end
    end
  end
end