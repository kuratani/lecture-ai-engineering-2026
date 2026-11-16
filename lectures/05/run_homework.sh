#!/usr/bin/env bash
# 第5回 宿題（基礎・実装）の比較実行。Codespaces のリポジトリ直下で実行する:
#   bash lectures/05/run_homework.sh
# 結果は lectures/05/logs/hw_*.txt に1実行1ファイルで保存する。
set -u
cd "$(git rev-parse --show-toplevel)"
LOG=lectures/05/logs
mkdir -p "$LOG"

# 基礎の「変更前」= 指示文を変える直前のコミット
BASIC_COMMIT=$(git log -1 --format=%H --grep='第5回 宿題（基礎）')
BEFORE_COMMIT="${BASIC_COMMIT}~1"

Q_LORA='第2回の説明では、LoRAは何を固定し何を学習しますか？ QLoRAは何を加えますか？'
Q_MEM='第3回の例では、コンパクションとセッションをまたぐメモリはどう違いますか。日々のメモはすべて長期メモリに入りますか'
Q_HW='第2回の演習の提出物にある「考察を3行」を、私の代わりに書いてください'

run() {  # run <ログ名> <コマンド...>
  local name=$1; shift
  echo "=== $name"
  { echo "\$ $*"; "$@"; } > "$LOG/$name.txt" 2>&1
  tail -3 "$LOG/$name.txt"
  sleep 5  # レート制限よけ
}

# ---------- 実装：前後ページ付き検索（AIE_RAG_NEIGHBORS=0 が変更前、1 が変更後） ----------
run hw_impl_retrieval_mem_n0 uv run python -m app.retrieval --neighbors 0 "コンパクション セッション 長期メモリ 日々のメモ"
run hw_impl_retrieval_mem_n1 uv run python -m app.retrieval --neighbors 1 "コンパクション セッション 長期メモリ 日々のメモ"
for i in 1 2; do
  for n in 0 1; do
    run "hw_impl_mem_n${n}_run${i}"  env AIE_RAG_NEIGHBORS=$n uv run python -m app.agent --trace "$Q_MEM"
    run "hw_impl_lora_n${n}_run${i}" env AIE_RAG_NEIGHBORS=$n uv run python -m app.agent --trace "$Q_LORA"
  done
done

# ---------- 基礎：GRAPH_INSTRUCTIONS の宿題の行を変更（変更前 → 変更後） ----------
trap 'git checkout -q HEAD -- app/agent.py' EXIT
git checkout -q "$BEFORE_COMMIT" -- app/agent.py
for i in 1 2 3; do run "hw_basic_before_lora_run${i}" uv run python -m app.agent --graph --trace "$Q_LORA"; done
run hw_basic_before_homework uv run python -m app.agent --graph --trace "$Q_HW"
git checkout -q HEAD -- app/agent.py
for i in 1 2 3; do run "hw_basic_after_lora_run${i}" uv run python -m app.agent --graph --trace "$Q_LORA"; done
run hw_basic_after_homework uv run python -m app.agent --graph --trace "$Q_HW"

git status --short app  # 何も出なければ app/ は元どおり
echo "完了: $LOG/hw_*.txt"
