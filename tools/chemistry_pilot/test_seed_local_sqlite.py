import json
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).parent
class LocalSeedIntegrationTests(unittest.TestCase):
    def test_seed_reset_and_repeat_are_deterministic(self):
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "learning.sqlite"
            con = sqlite3.connect(db)
            schema = {
                "attempts":"id TEXT", "learningStates":"questionID TEXT", "syncOutbox":"id TEXT",
                "studySessions":"id TEXT", "remoteQuestionMappings":"localQuestionID TEXT",
                "courses":"id TEXT,payloadJSON TEXT,updatedAt REAL",
                "studyProfile":"id INTEGER,payloadJSON TEXT,updatedAt REAL",
                "materials":"id TEXT,title TEXT,subject TEXT,topic TEXT,description TEXT,author TEXT,kind TEXT,source TEXT,createdAt REAL,updatedAt REAL",
                "materialFields":"id TEXT,materialID TEXT,key TEXT,title TEXT,position INTEGER",
                "knowledgeRows":"id TEXT,materialID TEXT,position INTEGER,valuesJSON TEXT",
                "questionRules":"id TEXT,materialID TEXT,kind TEXT,promptFieldKey TEXT,answerFieldKey TEXT,promptTemplate TEXT,promptFieldKeysJSON TEXT,answersJSON TEXT,showCorrectCount INTEGER,enabled INTEGER",
            }
            for table, columns in schema.items():
                con.execute(f'CREATE TABLE "{table}" ({columns})')
            con.commit()
            cmd = [sys.executable,str(HERE/"seed_local_sqlite.py"),"--db",str(db)]
            preview = subprocess.run(cmd,capture_output=True,text=True)
            self.assertEqual(preview.returncode,0,preview.stderr)
            self.assertEqual(con.execute("SELECT count(*) FROM courses").fetchone()[0],0)
            for _ in range(2):
                result = subprocess.run(cmd+["--apply","--reset-learning-data"],capture_output=True,text=True)
                self.assertEqual(result.returncode,0,result.stderr)
                self.assertEqual(con.execute("SELECT count(*) FROM knowledgeRows").fetchone()[0],323)
                self.assertEqual(con.execute("SELECT count(*) FROM materials").fetchone()[0],36)
                self.assertEqual(con.execute("SELECT count(*) FROM courses").fetchone()[0],1)
                course = json.loads(con.execute("SELECT payloadJSON FROM courses").fetchone()[0])
                self.assertEqual(course["goals"][0]["masteryTarget"],90)
                self.assertEqual(len(course["sections"]),5)
            con.close()

if __name__ == "__main__":
    unittest.main()
