#!/bin/bash

# =============================================================================
# Git Commit Script for DonDameYO App
# =============================================================================
# 
# このスクリプトは開発者Yamato用のGitワークフローを自動化します。
# 
# 使用方法:
#   ./git_commit.sh "コミットメッセージ"
#   ./git_commit.sh "コミットメッセージ" --push
#   ./git_commit.sh "コミットメッセージ" --feature "新機能名"
# 
# オプション:
#   --push              : 現在のブランチにプッシュ
#   --feature "名前"    : 新しいfeatureブランチを作成
#   --main              : mainブランチに戻る
#   --help              : ヘルプを表示
# 
# =============================================================================

set -e  # エラー時に停止

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}===============================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}===============================================${NC}"
}

# ヘルプ表示
show_help() {
    echo -e "${CYAN}DonDameYO Git Commit Script${NC}"
    echo ""
    echo "使用方法:"
    echo "  ./git_commit.sh \"コミットメッセージ\""
    echo "  ./git_commit.sh \"コミットメッセージ\" --push"
    echo "  ./git_commit.sh \"コミットメッセージ\" --feature \"新機能名\""
    echo ""
    echo "オプション:"
    echo "  --push              : 現在のブランチにプッシュ"
    echo "  --feature \"名前\"    : 新しいfeatureブランチを作成"
    echo "  --main              : mainブランチに戻る"
    echo "  --help              : このヘルプを表示"
    echo ""
    echo "例:"
    echo "  ./git_commit.sh \"🔧 Firebase設定を追加\""
    echo "  ./git_commit.sh \"✨ P2P通信機能を実装\" --push"
    echo "  ./git_commit.sh \"🚀 QRコード機能を追加\" --feature \"qr-code\""
    exit 0
}

# 引数解析
COMMIT_MESSAGE=""
SHOULD_PUSH=false
FEATURE_NAME=""
SWITCH_TO_MAIN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            ;;
        --push)
            SHOULD_PUSH=true
            shift
            ;;
        --feature)
            FEATURE_NAME="$2"
            shift 2
            ;;
        --main)
            SWITCH_TO_MAIN=true
            shift
            ;;
        *)
            if [[ -z "$COMMIT_MESSAGE" ]]; then
                COMMIT_MESSAGE="$1"
            fi
            shift
            ;;
    esac
done

# mainブランチに切り替える場合
if [[ "$SWITCH_TO_MAIN" == true ]]; then
    log_header "Switching to main branch"
    git checkout main
    git pull origin main
    log_success "Switched to main branch and pulled latest changes"
    exit 0
fi

# コミットメッセージが空の場合はエラー
if [[ -z "$COMMIT_MESSAGE" ]] && [[ -z "$FEATURE_NAME" ]]; then
    log_error "コミットメッセージが必要です"
    echo "使用方法: ./git_commit.sh \"コミットメッセージ\""
    echo "ヘルプ: ./git_commit.sh --help"
    exit 1
fi

# 現在のブランチを取得
CURRENT_BRANCH=$(git branch --show-current)
log_info "現在のブランチ: $CURRENT_BRANCH"

# 新しいfeatureブランチを作成する場合
if [[ -n "$FEATURE_NAME" ]]; then
    log_header "Creating new feature branch: feature/$FEATURE_NAME"
    
    # mainブランチから新しいブランチを作成
    git checkout main
    git pull origin main
    git checkout -b "feature/$FEATURE_NAME"
    
    log_success "Created and switched to feature/$FEATURE_NAME"
    CURRENT_BRANCH="feature/$FEATURE_NAME"
    
    # featureブランチ作成時はコミットメッセージがあればコミット
    if [[ -n "$COMMIT_MESSAGE" ]]; then
        log_info "Initial commit for feature branch"
    else
        log_info "Feature branch created. Add your changes and run this script again with a commit message."
        exit 0
    fi
fi

# 作業ディレクトリの状態確認
log_header "Git Status Check"
git status

# 変更があるかチェック
if git diff-index --quiet HEAD --; then
    log_warning "変更がありません。何もコミットしません。"
    exit 0
fi

# ステージング
log_info "Adding changes to staging area..."
git add .

# コミット
log_info "Committing changes..."
if [[ -n "$COMMIT_MESSAGE" ]]; then
    git commit -m "$COMMIT_MESSAGE"
    log_success "Committed: $COMMIT_MESSAGE"
else
    log_error "コミットメッセージが必要です"
    exit 1
fi

# 注意: ichihara_yamatoブランチの自動処理はコメントアウト
# 現在はmainブランチで直接作業
if false; then  # 無効化
    # ichihara_yamatoブランチの処理
    if [[ "$CURRENT_BRANCH" != "ichihara_yamato" ]] && [[ "$CURRENT_BRANCH" != main* ]]; then
        log_header "Updating ichihara_yamato branch"
        
        # ichihara_yamatoブランチが存在するかチェック
        if git show-ref --verify --quiet refs/heads/ichihara_yamato; then
            log_info "ichihara_yamatoブランチが存在します"
            git checkout ichihara_yamato
            git merge "$CURRENT_BRANCH" --no-edit
        else
            log_info "ichihara_yamatoブランチを作成します"
            git checkout -b ichihara_yamato
            git merge "$CURRENT_BRANCH" --no-edit
        fi
        
        log_success "ichihara_yamatoブランチを更新しました"
    else
        log_info "Already on ichihara_yamato or main branch"
    fi
fi

# プッシュ処理
if [[ "$SHOULD_PUSH" == true ]]; then
    log_header "Pushing to remote repository"
    
    # 現在のブランチにプッシュ
    PUSH_BRANCH=$(git branch --show-current)
    log_info "Pushing to remote $PUSH_BRANCH branch"
    git push origin "$PUSH_BRANCH"
    
    log_success "Successfully pushed to origin/$PUSH_BRANCH"
else
    log_info "プッシュをスキップしました。プッシュするには --push オプションを使用してください。"
fi

# 最終状態表示
log_header "Final Status"
log_info "Current branch: $(git branch --show-current)"
log_info "Last commit: $(git log -1 --oneline)"

if [[ "$SHOULD_PUSH" == true ]]; then
    log_success "🎉 Changes committed and pushed successfully!"
else
    log_success "✅ Changes committed successfully!"
    echo ""
    echo -e "${YELLOW}💡 Tip: Run with --push to push to remote repository${NC}"
    echo "   ./git_commit.sh \"message\" --push"
fi

echo ""
log_info "GitHub Repository: https://github.com/ichihara-yamato/dondameyo"
