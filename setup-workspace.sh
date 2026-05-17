#!/bin/bash

# ワークスペース構造セットアップスクリプト
# このスクリプトは、READMEに記載されているディレクトリ構造を~/下に作成します
# 既存のディレクトリは無視されます

set -e  # エラーが発生したら終了

echo "=== Workspace Structure Setup ==="
echo ""

# ユーザー名の取得（GitHubユーザー名などに使用）
# デフォルトは現在のユーザー名
DEFAULT_USERNAME=$(whoami)
read -p "GitHubユーザー名を入力してください [デフォルト: $DEFAULT_USERNAME]: " GITHUB_USER
GITHUB_USER=${GITHUB_USER:-$DEFAULT_USERNAME}

# 作成するディレクトリのリスト
DIRECTORIES=(
    "$HOME/.config"
    "$HOME/.local/bin"
    "$HOME/.local/share"
    "$HOME/.local/state"
    "$HOME/.cache"
    "$HOME/github.com/$GITHUB_USER"
    "$HOME/gitlab.com/$GITHUB_USER"
    "$HOME/gist.github.com/$GITHUB_USER"
    "$HOME/sandbox"
    "$HOME/Documents/presentations"
    "$HOME/Documents/papers"
    "$HOME/Documents/notes"
    "$HOME/Documents/memo"
)

# 既存のディレクトリと新規作成されるディレクトリを分類
EXISTING_DIRS=()
NEW_DIRS=()

for dir in "${DIRECTORIES[@]}"; do
    if [ -d "$dir" ]; then
        EXISTING_DIRS+=("$dir")
    else
        NEW_DIRS+=("$dir")
    fi
done

# プレビュー表示
echo "=== ディレクトリ構造プレビュー ==="
echo ""

if [ ${#EXISTING_DIRS[@]} -gt 0 ]; then
    echo "✓ 既存のディレクトリ（スキップ）:"
    for dir in "${EXISTING_DIRS[@]}"; do
        echo "  - $dir"
    done
    echo ""
fi

if [ ${#NEW_DIRS[@]} -gt 0 ]; then
    echo "→ 新規作成されるディレクトリ:"
    for dir in "${NEW_DIRS[@]}"; do
        echo "  + $dir"
    done
    echo ""
    echo "合計 ${#NEW_DIRS[@]} 個のディレクトリを作成します"
else
    echo "すべてのディレクトリが既に存在します。"
    echo "新規作成するディレクトリはありません。"
fi

echo ""

# 確認
if [ ${#NEW_DIRS[@]} -eq 0 ]; then
    # 新規作成がない場合はPATHのチェックのみ行う
    echo "PATH設定のみ確認します..."
else
    read -p "ディレクトリを作成しますか? [y/N]: " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "セットアップをキャンセルしました。"
        exit 0
    fi

    echo ""
    echo "ディレクトリを作成中..."

    # ディレクトリ作成
    CREATED_COUNT=0
    for dir in "${NEW_DIRS[@]}"; do
        if mkdir -p "$dir"; then
            echo "  + $dir"
            CREATED_COUNT=$((CREATED_COUNT + 1))
        else
            echo "  ✗ 作成失敗: $dir"
        fi
    done

    echo ""
    echo "✓ $CREATED_COUNT 個のディレクトリを作成しました"
fi

# ~/.local/binをPATHに追加（まだ追加されていない場合）
echo ""

# 使用中のシェルを検出
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "$(which zsh)" ] || [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
    SHELL_NAME="bash"
else
    echo "⚠ .zshrcまたは.bashrcが見つかりません"
    echo "  手動で以下を設定ファイルに追加してください："
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    SHELL_CONFIG=""
fi

if [ -n "$SHELL_CONFIG" ]; then
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_CONFIG" 2>/dev/null; then
        echo "${SHELL_CONFIG}に~/.local/binをPATHに追加中..."
        echo '' >> "$SHELL_CONFIG"
        echo '# User binaries' >> "$SHELL_CONFIG"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
        echo "✓ ${SHELL_CONFIG}を更新しました"
        echo "  変更を反映するには 'source ${SHELL_CONFIG}' を実行してください"
    else
        echo "✓ ~/.local/binは既にPATHに追加されています"
    fi
fi

echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "完成したディレクトリ構造:"
echo ""
echo "~/
├── .config/              # アプリケーション設定
├── .local/
│   ├── bin/             # ユーザー専用バイナリ
│   ├── share/           # アプリケーションデータ
│   └── state/           # 状態・ログ
├── .cache/              # キャッシュ
├── github.com/
│   └── $GITHUB_USER/
├── gitlab.com/
│   └── $GITHUB_USER/
├── gist.github.com/
│   └── $GITHUB_USER/
├── sandbox/             # 実験・一時プロジェクト
└── Documents/
    ├── presentations/   # Marpスライド
    ├── papers/          # 論文PDF
    ├── notes/           # 研究ノート
    └── memo/            # メモ"

echo ""
echo "次のステップ:"
if [ -n "$SHELL_CONFIG" ]; then
    echo "  1. source ${SHELL_CONFIG} でPATHを反映"
else
    echo "  1. シェル設定ファイルにPATHを手動で追加"
fi
echo "  2. READMEのヘルパー関数をdotfilesに追加して使用"
echo ""
