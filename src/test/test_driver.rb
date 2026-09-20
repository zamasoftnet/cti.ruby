require_relative '../code/CTI'
require 'fileutils'
require 'minitest/autorun'
require 'socket'
require 'openssl'

module CTIDriverTests
  include CTI

  DATA_DIR = File.expand_path(File.join(__dir__, 'data'))
  OUT_DIR = File.expand_path(File.join(__dir__, 'out'))
  HOST = ENV.fetch('CTI_TEST_HOST', 'cti.li')
  PORT = (ENV['CTI_TEST_PORT'] || '8099').to_i
  USER = ENV.fetch('CTI_TEST_USER', 'user')
  PASSWORD = ENV.fetch('CTI_TEST_PASSWORD', 'kappa')
  URI = ENV.fetch('CTI_SERVER_URI', 'ctip://cti.li/')
  # 接続試験マトリクスの共通契約(copperpdf4/docs/design/2026-09-20-cti-driver-tls-test-matrix-design.md §2):
  # CTI_TLS_INSECURE=1 で証明書を検証しない、CTI_EXPECT_REJECT=1 で「証明書の検証で拒否されること」だけを試験する
  INSECURE = ENV['CTI_TLS_INSECURE'] == '1'
  EXPECT_REJECT = ENV['CTI_EXPECT_REJECT'] == '1'
  raise 'CTI_TLS_INSECURE=1 と CTI_EXPECT_REJECT=1 は同時に指定できません' if INSECURE && EXPECT_REJECT

  def self.server_available?
    uri = URI.dup
    host = HOST
    port = PORT
    if URI =~ %r{\Actips?://([^:/]+):(\d+)/?}
      host = Regexp.last_match(1)
      port = Regexp.last_match(2).to_i
    elsif URI =~ %r{\Actips?://([^:/]+)/?}
      host = Regexp.last_match(1)
    end

    TCPSocket.open(host, port).close
    true
  rescue StandardError
    false
  end

  AVAILABLE = server_available?

  def self.data_path(name)
    File.join(DATA_DIR, name)
  end
end

if CTIDriverTests::EXPECT_REJECT
  # 拒否試験(tls-reject / tls-badname): 接続を起こし、証明書の検証エラーで拒否されることだけを確かめる。
  # 変換まで進む・DNS・接続拒否・認証失敗は成功に数えない
  class TestCTIReject < Minitest::Test
    include CTIDriverTests

    def test_certificate_verification_rejects
      error = assert_raises(OpenSSL::SSL::SSLError) do
        get_session(CTIDriverTests::URI, 'user' => CTIDriverTests::USER, 'password' => CTIDriverTests::PASSWORD)
      end
      puts "CTI-MATRIX reject: #{error.message}"
      assert_match(/certificate verify failed|hostname/i, error.message)
    end
  end
end

unless CTIDriverTests::EXPECT_REJECT
class TestCTIDriver < Minitest::Test
  include CTIDriverTests

  def setup
    skip("Copper PDF サーバー (#{CTIDriverTests::HOST}:#{CTIDriverTests::PORT}) に接続できないためスキップします。") unless CTIDriverTests::AVAILABLE
    FileUtils.mkdir_p(CTIDriverTests::OUT_DIR)
  end

  def transcode_html(session, output_file)
    session.set_output_as_file(output_file)

    open(CTIDriverTests.data_path('test.css'), 'rb') do |source|
      session.resource('test.css') do |out|
        CTI.copy_stream(source, out)
      end
    end

    session.transcode do |out|
      open(CTIDriverTests.data_path('test.html'), 'rb') do |source|
        CTI.copy_stream(source, out)
      end
    end
  end

  def assert_pdf(path)
    assert File.exist?(path), "#{path} が生成されること"
    open(path, 'rb') do |fp|
      assert_equal '%PDF', fp.read(4)
    end
  end

  def session_options
    opts = { 'user' => CTIDriverTests::USER, 'password' => CTIDriverTests::PASSWORD }
    opts['insecure'] = true if CTIDriverTests::INSECURE
    opts
  end

  def with_session
    get_session(CTIDriverTests::URI, session_options) do |session|
      yield session
    end
  end

  def test_server_info
    with_session do |session|
      info = session.get_server_info('http://www.cssj.jp/ns/ctip/version')
      assert info.is_a?(String)
      assert info.length > 0
    end
  end

  def test_authentication_failure
    assert_raises(RuntimeError) do
      get_session(CTIDriverTests::URI, session_options.merge('user' => 'invalid-user', 'password' => 'invalid-password'))
    end
  end

  def test_transcode_to_file
    output_file = File.join(CTIDriverTests::OUT_DIR, 'ruby-integration.pdf')
    FileUtils.rm_f(output_file)

    with_session do |session|
      transcode_html(session, output_file)
    end

    assert_pdf(output_file)
  end

  def test_transcode_to_output_directory
    output_dir = File.join(CTIDriverTests::OUT_DIR, 'output-dir')
    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)

    with_session do |session|
      session.property('output.type', 'image/jpeg')
      session.set_output_as_directory(output_dir, '', '.jpg')
      open(CTIDriverTests.data_path('test.html'), 'rb') do |source|
        session.transcode do |out|
          CTI.copy_stream(source, out)
        end
      end
    end

    image_files = Dir.glob(File.join(output_dir, '*.jpg'))
    assert image_files.length.positive?, '出力ディレクトリにJPEGファイルが生成される'
    assert File.size(image_files.first) > 0, '出力JPEGのサイズが0でない'
  end

  def test_property_setting
    output_file = File.join(CTIDriverTests::OUT_DIR, 'ruby-property.pdf')
    FileUtils.rm_f(output_file)

    with_session do |session|
      session.property('output.pdf.version', '1.5')
      transcode_html(session, output_file)
    end

    assert_pdf(output_file)
  end

  def test_progress_callback
    progress = []
    with_session do |session|
      session.set_results(Results::SingleResult.new(Builder::NullBuilder.new))
      session.receive_progress do |length, read|
        progress << [length, read]
      end
      session.property('input.include', 'https://www.w3.org/**')
      session.transcode_server('https://www.w3.org/TR/xslt-10/')
    end

    assert !progress.empty?, '進行状況コールバックが呼ばれる'
  end

  def test_resolver
    resolved = false
    output_file = File.join(CTIDriverTests::OUT_DIR, 'resolver.pdf')
    FileUtils.rm_f(output_file)

    with_session do |session|
      session.resolver do |uri, r|
        if uri == 'test.css'
          resolved = true
          r.found do |out|
            open(CTIDriverTests.data_path('test.css'), 'rb') do |source|
              CTI.copy_stream(source, out)
            end
          end
        end
      end

      session.set_output_as_file(output_file)
      session.transcode do |out|
        open(CTIDriverTests.data_path('test.html'), 'rb') do |source|
          CTI.copy_stream(source, out)
        end
      end
    end

    assert resolved, 'resolver が呼ばれてリソースが解決される'
    assert_pdf(output_file)
  end

  def test_reset
    output_1 = File.join(CTIDriverTests::OUT_DIR, 'reset-1.pdf')
    output_2 = File.join(CTIDriverTests::OUT_DIR, 'reset-2.pdf')
    FileUtils.rm_f(output_1)
    FileUtils.rm_f(output_2)

    with_session do |session|
      transcode_html(session, output_1)
      session.reset
      transcode_html(session, output_2)
    end

    assert_pdf(output_1)
    assert_pdf(output_2)
  end
end
end
