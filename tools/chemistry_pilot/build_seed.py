#!/usr/bin/env python3
"""Build deterministic chemistry pilot seed from the two source CSVs.

This is a development fixture, NOT the public .botai import format.
"""
import argparse
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path

def read(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f, delimiter=";"))

def build(study_path, test_path):
    study, test = read(study_path), read(test_path)
    assert len(study) == len(test) == 323, "Unexpected chemistry pilot size"
    a, b = {r["id"]: r for r in study}, {r["id"]: r for r in test}
    assert len(a) == len(b) == 323 and a.keys() == b.keys(), "Missing or duplicate IDs"
    questions = []
    for key in sorted(a):
        s, t = a[key], b[key]
        for field in ("раздел", "тема", "набор_знаний", "вопрос"):
            assert s[field].strip() and s[field] == t[field], (key, field)
        assert s["ответ"] == t["правильный_ответ"], key
        choices = []
        for letter in "ABCD":
            for candidate in (f"вариант_{letter}", f"вариант_{letter.lower()}", letter):
                if candidate in t:
                    choices.append({"key": letter, "text": t[candidate]})
                    break
        assert len(choices) == 4 and next(c["text"] for c in choices if c["key"] == t["правильный_вариант"]) == s["ответ"], key
        questions.append({
            "id": key, "section": s["раздел"], "topic": s["тема"],
            "knowledge_set": s["набор_знаний"], "question": s["вопрос"],
            "answer": s["ответ"],
            "accepted_answers": [x.strip() for x in s.get("допустимые_ответы", "").split("|") if x.strip()] or [s["ответ"]],
            "choices": choices, "correct_choice": t["правильный_вариант"],
            "source_code": s.get("код_кодификатора_2027", "")
        })
    return {"schema": "botai.chemistry.pilot.v1", "subject": "Химия",
            "course": {"title": "ЕГЭ — Химия 2027", "deadline": "2026-12-31",
                       "mastery_target": 0.9, "daily_minutes_initial": 25,
                       "study_days_per_week": 6},
            "questions": questions}

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--study", type=Path, required=True)
    p.add_argument("--test", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    args = p.parse_args()
    result = build(args.study, args.test)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Questions:", len(result["questions"]))
    print("Sections:", dict(Counter(q["section"] for q in result["questions"])))
    print("SHA256:", hashlib.sha256(args.out.read_bytes()).hexdigest())

if __name__ == "__main__":
    main()
