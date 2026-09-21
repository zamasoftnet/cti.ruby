# リリース手順

## リリース方法

`copper-cti.gemspec` の `spec.version` を更新し、バージョンタグを push します。

```bash
git tag v2.2.0
git push origin v2.2.0
```

GitHub Actions が以下を自動実行します：

1. RDoc によるAPIドキュメント生成
2. GitHub Releases にアーカイブを公開（`cti-ruby-{VERSION}.zip` / `.tar.gz`）
3. GitHub Pages にドキュメントをデプロイ

## RubyGems.org への公開

### Trusted Publishing（推奨。鍵も多要素認証も不要）

GitHub Actions から OIDC で認証して公開します。長期の API 鍵をリポジトリに置きません。
`release.yml` に手順は入っていますが、**リポジトリ変数 `RUBYGEMS_TRUSTED_PUBLISHING` が `true` のときだけ**動きます。

1. <https://rubygems.org/gems/copper-cti> にオーナーでログインし、Trusted publishers の追加で
   GitHub Actions の publisher を登録する（Repository owner `zamasoftnet`、Repository `cti.ruby`、
   Workflow filename `release.yml`、Environment は空欄）。
2. GitHub の Settings → Secrets and variables → Actions → Variables で
   `RUBYGEMS_TRUSTED_PUBLISHING` を `true` にする。
3. 以降は版タグを push するだけで、GitHub Releases と RubyGems の両方に出る。

### 手動で公開する場合

```bash
gem build copper-cti.gemspec -o build/copper-cti-{VERSION}.gem
gem push build/copper-cti-{VERSION}.gem
```

初回は `gem signin` でログインが必要です。多要素認証を設定していると、`gem push` が
`https://rubygems.org/webauthn_verification/...` を表示して待ちます。**この URL には手元のポートへの
戻り先が入っている**ので、同じ PC のブラウザで開いて承認してください（別の環境からは通せません）。
認証アプリの 6 桁コードがある場合は `--otp <コード>` でも通ります（API 鍵を渡す引数ではありません）。

## ドキュメント

- **GitHub Pages**: https://zamasoftnet.github.io/cti.ruby/
- リリース時に自動更新
