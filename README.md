# CTI Driver for Ruby

[Copper PDF](https://copper-pdf.com/) 文書変換サーバーに接続するためのRubyドライバです。

バージョン 2.1.1

使用方法は付属のAPIドキュメント、サンプルプログラム、以下のオンラインマニュアルを参照してください。

http://dl.cssj.jp/docs/copper/3.2/html/3424_ctip2_ruby.html

## API ドキュメント

- **オンライン (RDoc)**: https://zamasoftnet.github.io/cti.ruby/

## 動作要件

- Ruby 1.8.7以降

## インストール

### Bundler を使う方法（推奨）

`Gemfile` に以下を追加してください。

```ruby
gem 'copper-cti', git: 'https://github.com/zamasoftnet/cti.ruby.git'
```

その後 `bundle install` を実行します。

```bash
bundle install
```

インストール後は通常通りモジュールを使用できます。

```ruby
require 'CTI'
```

### gem コマンドを使う方法

```bash
gem install specific_install
gem specific_install https://github.com/zamasoftnet/cti.ruby.git
```

### 手動インストール

`src/code/` ディレクトリをプロジェクトにコピーし、`$LOAD_PATH` に追加してください。

```ruby
$LOAD_PATH.unshift('/path/to/src/code')
require 'CTI'
```

## 基本的な使い方

```ruby
require 'CTI/Session'
require 'CTI/Driver'

driver = CTI::Driver.new
session = driver.get_session('ctip://localhost:8099/', {
  'user' => 'user',
  'password' => 'kappa'
})

begin
  session.set_output_as_file('output.pdf')

  # CSSリソースを送信
  out = session.resource('test.css')
  File.open('data/test.css', 'rb') { |f| CTI::copy_stream(f, out) }
  out.close

  # HTML文書を変換
  out = session.transcode('test.html')
  File.open('data/test.html', 'rb') { |f| CTI::copy_stream(f, out) }
  out.close
ensure
  session.close
end
```

## API概要

### Session クラスの主要メソッド

| メソッド | 説明 |
| :--- | :--- |
| `get_server_info(uri)` | サーバー情報を取得 |
| `set_output_as_file(file)` | 変換結果の出力先ファイル名を指定 |
| `set_output_as_directory(dir, prefix, suffix)` | 変換結果の出力先ディレクトリ名を指定 |
| `set_output_as_stream(out)` | 変換結果の出力先IOオブジェクトを指定 |
| `set_results(results)` | 変換結果の出力先Resultsオブジェクトを指定 |
| `property(name, value)` | プロパティを設定 |
| `resource(uri, opts, &block)` | リソースを送信 |
| `transcode(uri, opts, &block)` | 変換対象の文書を送信し変換を実行 |
| `transcode_server(uri)` | サーバー側リソースを変換 |
| `receive_message(&block)` | メッセージ受信のためのブロックを設定 |
| `receive_progress(&block)` | 進行状況受信のためのブロックを設定 |
| `resolver(&block)` | リソース解決のためのブロックを設定 |
| `set_continuous(continuous)` | 複数結果の結合モードを切り替え |
| `join` | 結果を結合 |
| `abort(mode)` | 変換処理の中断を要求 |
| `reset` | 全ての状態をリセット |
| `close` | セッションを閉じる |

### モジュールメソッド

| メソッド | 説明 |
| :--- | :--- |
| `CTI::get_session(uri, options, &block)` | 指定されたURIに接続しセッションを返す |
| `CTI::get_driver(uri)` | 指定されたURIに接続するためのドライバを返す |
| `CTI::copy_stream(inp, out)` | ストリーム間のデータコピー |

## テストの実行方法

テストの実行にはCopper PDFサーバーが稼働している必要があります。

接続先は環境変数で指定できます（既定: localhost:8099 / user / kappa）。
テスト実行は `minitest` のユニットで、サーバー未接続時は自動的にスキップします。

```bash
ruby -Isrc/code src/test/test_driver.rb
```

Ant から実行する場合は `cti.ruby` 配下で以下を実行してください。

```bash
ant test
```

## ドキュメント生成方法

APIドキュメントはRDocで生成されます。Antの `rdoc` ターゲットを実行してください。

```bash
ant rdoc
```

`build/ruby/apidoc` ディレクトリにHTMLドキュメントが生成されます。

## ライセンス

Copyright (c) 2013-2022 Zamasoft.

Apache License Version 2.0に基づいてライセンスされます。
あなたがこのファイルを使用するためには、本ライセンスに従わなければなりません。
本ライセンスのコピーは下記の場所から入手できます。

http://www.apache.org/licenses/LICENSE-2.0

適用される法律または書面での同意によって命じられない限り、
本ライセンスに基づいて頒布されるソフトウェアは、明示黙示を問わず、
いかなる保証も条件もなしに「現状のまま」頒布されます。
本ライセンスでの権利と制限を規定した文言については、本ライセンスを参照してください。

Copyright (c) 2013-2022 Zamasoft.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## 変更履歴

### v2.1.1 (2026/3/9)
- Windows/Cygwin 環境でバイナリファイルをテキストモードで書き込むバグを修正。

### v2.1.0 (2022/1/24)
- Ruby 3に対応。FileUtilsまたはIOのcopy_streamではなくCTI::copy_streamを使用。

### v2.0.0 (2013/4/24)
- 最初のリリース。
