# Workspace Structure

ホームディレクトリの統一構造設計ドキュメント

## 概要

Ubuntu（USBブート）とWSL2環境で統一されたワークスペース構造の設計ドキュメントです。
- Go言語風のGitレポジトリ管理（`github.com/user/repo`）
- XDG Base Directory仕様準拠
- 実験プロジェクト管理（日付ベース）
- プレゼンテーション資料のアーカイブ管理

このドキュメントを参考に、各自の環境に合わせてカスタマイズしてください。

## ディレクトリ構造

```
~/
├── .config/              # アプリケーション設定（XDG_CONFIG_HOME）
├── .local/
│   ├── bin/             # ユーザー専用バイナリ（pipなど）
│   ├── share/           # アプリケーションデータ
│   └── state/           # 状態・ログ
├── .cache/              # キャッシュ（バックアップ不要）
│
# Git管理プロジェクト
├── github.com/
│   ├── ymd000/           # 個人レポジトリ
│   ├── research-lab/    # 共同研究組織など
│   └── microsoft/       # 他人のレポジトリ(フォークしてないもの)
├── gitlab.com/
│   └── ymd000/
└── gist.github.com/
    └── ymd000/
│
# 実験・一時プロジェクト
├── sandbox/             # 日付ディレクトリ、定期削除可能
│   ├── 2024-12-05/
│   │   ├── mil-test/
│   │   └── stat6-analysis/
│   └── 2024-12-10/
│       └── experiment/
│
# ドキュメント
└── Documents/
    ├── presentations/   # Marpスライド（年/月アーカイブ）
    │   └── 2024/
    │       └── 12/
    │           └── 2024-12-05-ai-study.md
    ├── papers/          # 論文PDF
    ├── notes/           # 研究ノート
    └── memo/            # メモ

```

## セットアップ

このプロジェクトは、ワークスペース構造の設計ドキュメントです。
実際のセットアップは、ユーザー自身がこのドキュメントを参考に行います。

### 基本的なディレクトリ作成

```bash
# XDG directories
mkdir -p ~/.config
mkdir -p ~/.local/{bin,share,state}
mkdir -p ~/.cache

# Git hosting structure
mkdir -p ~/github.com/ymd000
mkdir -p ~/gitlab.com/ymd000
mkdir -p ~/gist.github.com/ymd000

# Sandbox
mkdir -p ~/sandbox

# Documents
mkdir -p ~/Documents/{presentations,papers,notes}

# PATHに~/.local/binを追加
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### ヘルパー関数

```bash
# Marpテーマをインストール
mkdir -p ~/.config/marp/themes
cp ~/github.com/ymd000/workspaece-structure/marp/themes/demo.css ~/.config/marp/themes/

# ヘルパー関数を読み込む（.zshrc または .bashrc に追記）
echo 'source ~/github.com/ymd000/workspaece-structure/marp/functions.sh' >> ~/.zshrc

# Marp CLI をインストール（未インストールの場合）
npm install -g @marp-team/marp-cli
```


## ヘルパー関数

### プロジェクト管理

| コマンド | 説明 | 例 |
|---------|------|-----|
| `new-project <name>` | sandboxに新規プロジェクト作成 | `new-project mil-test` |
| `promote-to-git` | 現在のsandboxプロジェクトをGit化 | `promote-to-git` |
| `git-promote-finish <name>` | Git化したプロジェクトをGitHubへ移動 | `git-promote-finish mil-test` |
| `gclone <url>` | Gitレポジトリを適切な構造でクローン | `gclone https://github.com/microsoft/TypeScript` |
| `grepo <keyword>` | レポジトリを検索して移動 | `grepo TypeScript` |
| `clean-sandbox [days]` | 古い日付ディレクトリを削除 | `clean-sandbox 30` |

### プレゼンテーション管理

| コマンド | 説明 | 例 |
|---------|------|-----|
| `new-marp <title>` | 新規Marpプレゼンテーション作成 | `new-marp ai-study` |
| `list-marp [year] [month]` | プレゼンテーション一覧表示 | `list-marp 2024 12` |
| `edit-marp <keyword>` | プレゼンテーションを検索して編集 | `edit-marp ai-study` |

## ワークフロー例

### 新しいアイデアの実験

```bash
# 1. 実験プロジェクト作成
new-project mil-cv-test
# → ~/sandbox/2024-12-05/mil-cv-test/

# 2. コードを書く
nvim experiment.py

# 3. プレゼン資料作成（自動でシンボリックリンク）
new-marp progress-report
# → ~/Documents/presentations/2024/12/2024-12-05-progress-report.md
# → ./2024-12-05-progress-report.md (symlink)
```

### プロジェクトのGit化

```bash
# 4. Git化
cd ~/sandbox/2024-12-05/mil-cv-test/
promote-to-git

# 5. GitHubでレポジトリ作成後
git-promote-finish mil-cv-test
# → ~/github.com/ymd000/mil-cv-test/
```

### 共同研究

```bash
# 研究室のレポジトリをクローン
gclone git@github.com:research-lab/pathology-study.git
# → ~/github.com/research-lab/pathology-study/

cd ~/github.com/research-lab/pathology-study/
new-marp progress-update
# プロジェクト内にシンボリックリンク作成
```

### 定期メンテナンス

```bash
# 30日以上前の日付ディレクトリを掃除
clean-sandbox 30
```

## バックアップ戦略

### 優先度：高（必須）
- `~/.config/` - アプリケーション設定
- `~/.local/` - ユーザーデータ・バイナリ
- `~/Documents/` - プレゼン・論文・ノート
- `~/sandbox/` - Git化していない重要プロジェクト

### 優先度：低（任意）
- `~/github.com/` - Git pushされていれば不要
- `~/gitlab.com/` - Git pushされていれば不要
- `~/.cache/` - 再生成可能

## dotfilesとの統合

このワークスペース構造は、dotfilesレポジトリと組み合わせて使用することを推奨します：

```bash
# dotfilesレポジトリに統合
~/github.com/ymd000/dotfiles/
├── config/
│   └── bash/
│       └── functions.sh  # このプロジェクトのヘルパー関数
├── bash/
│   └── bashrc
└── install.sh

# シンボリックリンク
~/.config/bash/functions.sh -> ~/github.com/ymd000/dotfiles/config/bash/functions.sh
```

## トラブルシューティング

### ヘルパー関数が使えない

```bash
# 読み込まれているか確認
type new-project

# 手動で読み込み
source ~/.config/bash/functions.sh

# .bashrcの設定を確認
grep "functions.sh" ~/.bashrc
```

### シンボリックリンクが切れている

```bash
# プレゼンテーションのシンボリックリンクを確認
ls -la ~/github.com/ymd000/*/2024-*.md

# 再作成
cd ~/github.com/ymd000/your-project/
ln -sf ~/Documents/presentations/2024/12/2024-12-05-title.md ./2024-12-05-title.md
```

## 参考

- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Go Workspaces](https://go.dev/doc/tutorial/workspaces)
- [Marp](https://marp.app/)

## 作者

ymd000
