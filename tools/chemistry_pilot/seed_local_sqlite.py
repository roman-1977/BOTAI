#!/usr/bin/env python3
"""Development-only seed for an EXISTING migrated BOTAI SQLite database.

Never run against Supabase. Requires --reset-learning-data for destructive reset.
Close the app first. Back up the database before invoking.
"""
import argparse
import datetime as dt
import json
import sqlite3
import uuid
from collections import defaultdict
from pathlib import Path

NS = uuid.UUID("ae5a7dd9-75e0-488f-9bb4-68e16c35020e")
def uid(value):
    return str(uuid.uuid5(NS, "botai-chemistry-2027:" + value)).upper()

def apple_date(date):
    return (date - dt.datetime(2001, 1, 1, tzinfo=dt.timezone.utc)).total_seconds()

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--db", type=Path, required=True, help="existing migrated learning.sqlite")
    p.add_argument("--seed", type=Path, default=Path(__file__).with_name("chemistry_seed.json"))
    p.add_argument("--reset-learning-data", action="store_true", help="explicitly authorize deletion of local learning records")
    p.add_argument("--apply", action="store_true", help="otherwise only validate/preview")
    args = p.parse_args()
    data = json.loads(args.seed.read_text(encoding="utf-8"))
    questions = data["questions"]
    assert len(questions) == len({q["id"] for q in questions}) == 323
    groups = defaultdict(list)
    for q in questions:
        assert len(q["choices"]) == 4
        assert next(c["text"] for c in q["choices"] if c["key"] == q["correct_choice"]) == q["answer"]
        groups[(q["section"], q["topic"], q["knowledge_set"], q["correct_choice"])].append(q)
    print("Validated", len(questions), "knowledge questions in", len(groups), "sets")
    if not args.apply:
        print("Preview only. No database modified.")
        return
    if not args.reset_learning_data:
        p.error("--apply requires --reset-learning-data; use only on disposable local learning.sqlite")
    if not args.db.is_file():
        p.error("Database must exist and already be migrated by the iOS app")
    con = sqlite3.connect(str(args.db))
    try:
        con.execute("PRAGMA foreign_keys=ON")
        tables = {x[0] for x in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        needed = {"attempts", "learningStates", "syncOutbox", "studySessions", "courses", "materials", "materialFields", "knowledgeRows", "questionRules", "studyProfile", "remoteQuestionMappings", "knowledgeStates"}
        if not needed.issubset(tables):
            raise RuntimeError("SQLite migrations incomplete: " + str(sorted(needed - tables)))
        now = dt.datetime.now(dt.timezone.utc)
        ts = apple_date(now)
        refs = {}
        sections = defaultdict(lambda: defaultdict(list))
        with con:
            # All deletes are deliberately scoped to learning data in the selected local account DB.
            for table in ("syncOutbox", "remoteQuestionMappings", "attempts", "learningStates", "knowledgeStates", "studySessions", "courses", "studyProfile", "materialFields", "knowledgeRows", "questionRules", "materials"):
                con.execute(f'DELETE FROM "{table}"')
            for index, ((section, topic, name, correct_letter), rows) in enumerate(sorted(groups.items())):
                mid, card_rule, choice_rule = uid("material:"+section+":"+topic+":"+name+":"+correct_letter), uid("card:"+section+":"+topic+":"+name+":"+correct_letter), uid("choice:"+section+":"+topic+":"+name+":"+correct_letter)
                con.execute("INSERT INTO materials(id,title,subject,topic,description,author,kind,source,createdAt,updatedAt) VALUES(?,?,?,?,?,?,?,?,?,?)", (mid,name+" ["+correct_letter+"]","Химия",topic,section,"BOTAI Pilot","quiz","created",ts,ts))
                fields = ["question", "answer", "A", "B", "C", "D"]
                for pos, key in enumerate(fields):
                    con.execute("INSERT INTO materialFields(id,materialID,key,title,position) VALUES(?,?,?,?,?)", (uid(mid+":field:"+key),mid,key,key,pos))
                for pos, q in enumerate(rows):
                    values = {"question":q["question"],"answer":q["answer"]}
                    values.update({c["key"]:c["text"] for c in q["choices"]})
                    con.execute("INSERT INTO knowledgeRows(id,materialID,position,valuesJSON) VALUES(?,?,?,?)", (uid("row:"+q["id"]),mid,pos,json.dumps(values,ensure_ascii=False)))
                card_answers = [{"template":"{1}","fieldKeys":["answer"],"correct":True}]
                choice_answers = [{"template":"{1}","fieldKeys":[letter],"correct":letter == correct_letter} for letter in "ABCD"]
                # If correct letters differ between rows, one rule cannot encode correctness.
                # Split multiple-choice rules by answer key to keep all questions correct.
                for rid, kind, ans in ((card_rule,"card",card_answers),(choice_rule,"singleChoice",choice_answers)):
                    con.execute("INSERT INTO questionRules(id,materialID,kind,promptFieldKey,answerFieldKey,promptTemplate,promptFieldKeysJSON,answersJSON,showCorrectCount,enabled) VALUES(?,?,?,?,?,?,?,?,?,?)",
                                (rid,mid,kind,"question","answer","{1}",json.dumps(["question"]),json.dumps(ans),0,1))
                refs[(section,topic,name,correct_letter,"card")] = {"materialID":mid,"ruleID":card_rule}
                refs[(section,topic,name,correct_letter,"choice")] = {"materialID":mid,"ruleID":choice_rule}
                sections[section][topic].extend([refs[(section,topic,name,correct_letter,"card")],refs[(section,topic,name,correct_letter,"choice")]])
            section_data = []
            for section, topics in sorted(sections.items()):
                section_data.append({"id":uid("section:"+section),"title":section,"description":"","estimatedMinutes":None,"topics":[{"id":uid("topic:"+section+":"+topic),"title":topic,"questionSets":refs} for topic,refs in sorted(topics.items())]})
            goal_refs = [ref for key, ref in refs.items() if key[-1] == "card"]
            deadline = dt.datetime(2026,12,31,23,59,59,tzinfo=dt.timezone.utc)
            course = {"id":uid("course"),"title":"ЕГЭ — Химия 2027","description":"Пилот адаптивного обучения: 323 знания, 31.12.2026","subject":"Химия","audience":"ЕГЭ","estimatedMinutes":None,"author":"BOTAI Pilot","language":"ru","coverSymbol":"flask.fill","source":"created","sections":section_data,"goals":[{"id":uid("goal"),"title":"Освоить 90% химии к 31 декабря","questionSets":goal_refs,"masteryTarget":90,"deadline":apple_date(deadline),"state":"active"}],"createdAt":apple_date(now),"updatedAt":apple_date(now)}
            con.execute("INSERT INTO courses(id,payloadJSON,updatedAt) VALUES(?,?,?)",(course["id"],json.dumps(course,ensure_ascii=False),ts))
            profile = {"defaultDailyMinutes":25,"customDays":[{"weekday":1,"minutes":0}],"updatedAt":apple_date(now)}
            con.execute("INSERT INTO studyProfile(id,payloadJSON,updatedAt) VALUES(1,?,?)",(json.dumps(profile),ts))
        print("Seeded:",len(questions),"knowledge rows,",len(groups),"materials,",len(section_data),"sections; 2 assessment modes, 1 active goal")
        print("Choice correctness is grouped by answer letter; both modes use the existing Swift rule model.")
    finally:
        con.close()

if __name__ == "__main__":
    main()
