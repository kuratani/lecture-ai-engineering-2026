"""第1回: 素のLLMに1回だけ質問するスクリプト。

使い方:
    uv run python -m app.ask "LoRAとは何ですか？"
    uv run python -m app.ask            # 質問を省略すると、講座に固有の質問をする
    AIE_TEMPERATURE=0.0 uv run python -m app.ask "LoRAとは何ですか？"   # temperature を指定（0.0〜2.0）

回答のあとは続けて質問できる（会話履歴を保持する）。空行か exit / Ctrl-D で終了。
ツールを持たない「素の」呼び出し。
講座に固有のことを聞くと、「分からない」と答えるか、一般論でもっともらしく答える
（講座の実際とは違う）ことを確かめよう。
（第3回で、用語集を検索できるエージェントにして改善する）
"""

import argparse
import time

from google import genai
from google.genai import errors, types
from google.genai.chats import Chat

from app.config import MODEL, TEMPERATURE, api_error_message, get_api_key

# 講座に固有の質問。正しい答えは data/glossary.json の homework-levels にある
DEFAULT_QUESTION = "AIE2026の講座の宿題にある「3レベル」とは何ですか？"


def ask(chat: Chat, question: str) -> str:
    """chat に質問を送る。chat が過去のやり取りを保持するので、続けて質問できる。"""
    start = time.perf_counter()
    response = chat.send_message(question)
    elapsed = time.perf_counter() - start

    message = f"[計測] 応答時間: {elapsed:.2f}秒"
    if response.usage_metadata is not None:
        usage = response.usage_metadata
        message += f", 入力: {usage.prompt_token_count}, 出力: {usage.candidates_token_count}"
    print(message + "\n")

    return response.text


def main() -> None:
    parser = argparse.ArgumentParser(description="素のLLMに質問する")
    parser.add_argument("question", nargs="?", default=DEFAULT_QUESTION)
    args = parser.parse_args()

    print(f"[model] {MODEL}")
    print(f"[temperature] {TEMPERATURE if TEMPERATURE is not None else '既定値'}")

    # client を変数で保持する。chat だけ残すと client が破棄されて接続が閉じる
    client = genai.Client(api_key=get_api_key())
    chat = client.chats.create(
        model=MODEL,
        config=types.GenerateContentConfig(temperature=TEMPERATURE),
    )
    question = args.question
    try:
        while True:
            print(f"[質問] {question}\n")
            print(ask(chat, question))
            try:
                question = input("\n次の質問（空行で終了）> ").strip()
            except EOFError:
                break
            if question in ("", "exit", "quit"):
                break
            print()
    except errors.APIError as e:
        print(api_error_message(e.code, e.message))
        raise SystemExit(1)


if __name__ == "__main__":
    main()
