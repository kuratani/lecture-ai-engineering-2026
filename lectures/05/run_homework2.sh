#!/usr/bin/env bash
# 第5回 宿題（実装）の追加比較：根拠が「隣のページ」に続く質問で、前後ページ付き検索を試す。
#   bash lectures/05/run_homework2.sh
# 結果は lectures/05/logs/hw2_*.txt に1実行1ファイルで保存する。
set -u
cd "$(git rev-parse --show-toplevel)"
LOG=lectures/05/logs
mkdir -p "$LOG"

# 根拠：第1回 p.40（100問中95問が正しそう、は十分か？）→ p.41（おそらく十分ではない。理由1・2）
Q_EVAL='第1回の例題で、開発者が質問を100個入力して95個が正しそうな回答だった場合、評価として十分ですか？ 理由も教えてください'
# 根拠：第1回 p.26（AIへの任せ方を広げる4つの方向）→ p.27（ただし、使えば良くなるとは限らない）
Q_USE='第1回で紹介された、AIへの任せ方を広げる4つの方向は何ですか？ その方向で使えば、仕事は必ず良くなりますか？'

run() {  # run <ログ名> <コマンド...>
  local name=$1; shift
  echo "=== $name"
  { echo "\$ $*"; "$@"; } > "$LOG/$name.txt" 2>&1
  tail -3 "$LOG/$name.txt"
  sleep 5  # レート制限よけ
}

# 検索だけ（前後ページなし）：根拠の2ページが上位5件に入るか
run hw2_retrieval_eval uv run python -m app.retrieval --neighbors 0 "$Q_EVAL"
run hw2_retrieval_use  uv run python -m app.retrieval --neighbors 0 "$Q_USE"

# エージェント：AIE_RAG_NEIGHBORS=0（変更前）と 1（変更後）を2回ずつ
for i in 1 2; do
  for n in 0 1; do
    run "hw2_eval_n${n}_run${i}" env AIE_RAG_NEIGHBORS=$n uv run python -m app.agent --trace "$Q_EVAL"
    run "hw2_use_n${n}_run${i}"  env AIE_RAG_NEIGHBORS=$n uv run python -m app.agent --trace "$Q_USE"
  done
done
echo "完了: $LOG/hw2_*.txt"
