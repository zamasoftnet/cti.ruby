#!/usr/bin/ruby
require 'CTI'
include CTI

SERVER_URI = 'ctip://cti.li/'
SOURCE_URI = 'http://cti.li/'
OUTPUT_DIR = File.expand_path('../../../test-output', __dir__)

Dir.mkdir(OUTPUT_DIR) unless Dir.exist?(OUTPUT_DIR)

def with_session(filename, &setup)
  session = get_session(SERVER_URI, 'user' => 'user', 'password' => 'kappa')
  session.set_output_as_file(File.join(OUTPUT_DIR, filename))
  begin
    setup.call(session)
  rescue => e
    $stderr.puts "エラー (#{filename}): #{e.message}"
    session.close rescue nil
    exit 0
  end
  session.close
  $stderr.puts "生成: #{filename}"
rescue => e
  $stderr.puts "接続エラー: #{e.message}"
  exit 0
end

SENTENCES = 'Copper PDFはHTMLやXMLをPDFに変換するサーバーサイドのソフトウェアです。' \
            'CTIプロトコルを通じてクライアントからドキュメントを送信し、変換結果をPDFとして受け取ります。' \
            'このテストは大量のテキストコンテンツを含む文書を生成します。' \
            'ドライバはPDF出力が2MBを超えた際にメモリからファイル書き出しへ切り替わります。' \
            'このテストはその動作を確認するために設計されています。'

# TC-01: 基本URL変換
with_session('ctip-ruby-url.pdf') do |session|
  session.transcode_server(SOURCE_URI)
end

# TC-02: ハイパーリンク有効
with_session('ctip-ruby-hyperlinks.pdf') do |session|
  session.property('output.pdf.hyperlinks', 'true')
  session.transcode_server(SOURCE_URI)
end

# TC-03: ブックマーク有効
with_session('ctip-ruby-bookmarks.pdf') do |session|
  session.property('output.pdf.bookmarks', 'true')
  session.transcode_server(SOURCE_URI)
end

# TC-04: ハイパーリンクとブックマーク有効
with_session('ctip-ruby-hyperlinks-bookmarks.pdf') do |session|
  session.property('output.pdf.hyperlinks', 'true')
  session.property('output.pdf.bookmarks', 'true')
  session.transcode_server(SOURCE_URI)
end

# TC-05: クライアント側HTML変換
with_session('ctip-ruby-client-html.pdf') do |session|
  html = '<html><body><h1>Hello</h1><p>Client-side HTML transcoding test.</p></body></html>'
  session.transcode('dummy:///test.html') do |out|
    out.write(html.encode('UTF-8'))
  end
end

# TC-06: 日本語HTMLコンテンツ
with_session('ctip-ruby-client-japanese.pdf') do |session|
  html = '<html><head><meta charset="UTF-8"/></head><body>' \
         '<h1>日本語テスト</h1><p>こんにちは世界。クライアント側から日本語コンテンツを送信します。</p>' \
         '</body></html>'
  session.transcode('dummy:///japanese.html') do |out|
    out.write(html.encode('UTF-8'))
  end
end

# TC-07: 最小HTML（境界条件）
with_session('ctip-ruby-client-minimal.pdf') do |session|
  session.transcode('dummy:///minimal.html') do |out|
    out.write('<html><body><p>.</p></body></html>')
  end
end

# TC-08: 連続モード（2文書を結合）
with_session('ctip-ruby-continuous.pdf') do |session|
  html1 = '<html><body><h1>Page 1</h1><p>First document in continuous mode.</p></body></html>'
  html2 = '<html><body><h1>Page 2</h1><p>Second document in continuous mode.</p></body></html>'
  session.set_continuous(true)
  session.transcode('dummy:///page1.html') do |out|
    out.write(html1.encode('UTF-8'))
  end
  session.transcode('dummy:///page2.html') do |out|
    out.write(html2.encode('UTF-8'))
  end
  session.join
end

# TC-09: 大規模テーブル（メモリ→ファイル切り替えを誘発）
with_session('ctip-ruby-large-table.pdf') do |session|
  session.transcode('dummy:///large-table.html') do |out|
    out.write('<html><head><meta charset="UTF-8"/></head><body>')
    out.write('<h1>大規模テーブルテスト</h1>')
    out.write('<table border="1"><tr><th>番号</th><th>名前</th><th>説明</th><th>備考</th></tr>')
    (1..15000).each do |i|
      out.write("<tr><td>#{i}</td><td>項目#{i}</td><td>これはテスト項目 #{i} の詳細説明テキストです。</td><td>備考テキスト #{i}</td></tr>")
    end
    out.write('</table></body></html>')
  end
end

# TC-10: 長文テキスト文書
with_session('ctip-ruby-large-text.pdf') do |session|
  session.transcode('dummy:///large-text.html') do |out|
    out.write('<html><head><meta charset="UTF-8"/></head><body>')
    (1..500).each do |s|
      out.write("<h2>セクション #{s}</h2>")
      (1..20).each do |p|
        out.write("<p>#{SENTENCES}（セクション#{s}、段落#{p}）</p>")
      end
    end
    out.write('</body></html>')
  end
end
