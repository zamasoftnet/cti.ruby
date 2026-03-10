# リリース手順

## リリース方法

`copper-cti.gemspec` の `spec.version` を更新し、バージョンタグを push します。

```bash
git tag v2.1.1
git push origin v2.1.1
```

GitHub Actions が以下を自動実行します：

1. RDoc によるAPIドキュメント生成
2. GitHub Releases にアーカイブを公開（`cti-ruby-{VERSION}.zip` / `.tar.gz`）
3. GitHub Pages にドキュメントをデプロイ

## RubyGems.org への公開（手動）

```bash
gem build copper-cti.gemspec
gem push copper-cti-{VERSION}.gem
```

初回は `gem signin` でログインが必要です。

## ドキュメント

- **GitHub Pages**: https://zamasoftnet.github.io/cti.ruby/
- リリース時に自動更新
