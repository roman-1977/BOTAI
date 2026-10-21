import csv
import tempfile
import unittest
from pathlib import Path
from build_seed import build

STUDY = ["id","раздел","тема","набор_знаний","вопрос","ответ","допустимые_ответы"]
TEST = ["id","раздел","тема","набор_знаний","вопрос","A","B","C","D","правильный_вариант","правильный_ответ"]

class ChemistrySeedTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.study = Path(self.tmp.name) / "study.csv"
        self.test = Path(self.tmp.name) / "test.csv"

    def write(self, path, fields, rows):
        with path.open("w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=fields, delimiter=";")
            w.writeheader()
            w.writerows(rows)

    def rows(self):
        s = [dict(id=f"I-{i:04}", раздел="Общая", тема="Атом", набор_знаний="Термины", вопрос=f"Q{i}?", ответ=f"A{i}", допустимые_ответы=f"A{i}") for i in range(323)]
        t = [dict(id=x["id"], раздел=x["раздел"], тема=x["тема"], набор_знаний=x["набор_знаний"], вопрос=x["вопрос"], A="wrong", B=x["ответ"], C="wrong2", D="wrong3", правильный_вариант="B", правильный_ответ=x["ответ"]) for x in s]
        return s, t

    def test_matched_sources_produce_one_knowledge_per_pair(self):
        s, t = self.rows()
        self.write(self.study, STUDY, s)
        self.write(self.test, TEST, t)
        result = build(self.study, self.test)
        self.assertEqual(len(result["questions"]), 323)
        self.assertEqual(result["questions"][0]["correct_choice"], "B")
        self.assertEqual(len(result["questions"][0]["choices"]), 4)

    def test_reject_mismatched_answer(self):
        s, t = self.rows()
        t[0]["правильный_ответ"] = "not the same"
        self.write(self.study, STUDY, s)
        self.write(self.test, TEST, t)
        with self.assertRaises(AssertionError):
            build(self.study, self.test)

    def test_reject_missing_question(self):
        s, t = self.rows()
        t.pop()
        self.write(self.study, STUDY, s)
        self.write(self.test, TEST, t)
        with self.assertRaises(AssertionError):
            build(self.study, self.test)

    def test_reject_incorrect_choice_key(self):
        s, t = self.rows()
        t[0]["правильный_вариант"] = "A"
        self.write(self.study, STUDY, s)
        self.write(self.test, TEST, t)
        with self.assertRaises(AssertionError):
            build(self.study, self.test)

if __name__ == "__main__":
    unittest.main()
