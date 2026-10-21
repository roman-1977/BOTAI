import json,uuid,urllib.request,urllib.error,pathlib
import os
base=os.environ['BOTAI_SUPABASE_URL'].rstrip('/')
conf=pathlib.Path('ios/BOTAI/Infrastructure/SupabaseConfiguration.swift').read_text()
key=conf.split('publishableKey = "')[1].split('"')[0]
def req(method,path,token=None,payload=None):
 h={'apikey':key,'Content-Type':'application/json'}
 if token:h['Authorization']='Bearer '+token
 if method=='POST':h['Prefer']='resolution=ignore-duplicates,return=representation'
 data=json.dumps(payload).encode() if payload is not None else None
 r=urllib.request.Request(base+path,data=data,headers=h,method=method)
 try:
  with urllib.request.urlopen(r,timeout=20) as x:return x.status,json.loads(x.read() or b'null')
 except urllib.error.HTTPError as e:
  return e.code,json.loads(e.read() or b'null')
a_status,a=req('POST','/auth/v1/signup',payload={})
assert a_status==200 and a.get('access_token'),'A signup failed'
b_status,b=req('POST','/auth/v1/signup',payload={})
assert b_status==200 and b.get('access_token'),'B signup failed'
ta,tb=a['access_token'],b['access_token']; qa=str(uuid.uuid4());va=str(uuid.uuid4());ia=str(uuid.uuid4());ib=str(uuid.uuid4());ua=a['user']['id'];ub=b['user']['id']
checks=[]
def check(name,ok):checks.append((name,ok));print(('PASS' if ok else 'FAIL'),name)
code,data=req('POST','/rest/v1/questions',ta,{'id':qa,'creator_user_id':ua,'question_type':'self_check'})
check('A creates private question',code in (200,201))
if code not in (200,201):print('error',code,str(data)[:300]);raise SystemExit(1)
code,data=req('POST','/rest/v1/question_versions',ta,{'id':va,'question_id':qa,'version_number':1,'prompt_text':'BOTAI RLS temporary fixture','created_by':ua})
check('A creates private version',code in (200,201))
code,data=req('GET',f'/rest/v1/questions?id=eq.{qa}&select=id',tb)
check('B cannot see private question',code==200 and data==[])
code,data=req('GET',f'/rest/v1/question_versions?id=eq.{va}&select=id',tb)
check('B cannot see private version',code==200 and data==[])
code,data=req('GET',f'/rest/v1/question_versions?id=eq.{va}&select=id',ta)
check('A sees own version',code==200 and len(data)==1)
code,data=req('POST','/rest/v1/attempts',ta,{'id':ia,'user_id':ua,'question_id':qa,'question_version_id':va,'result':'correct','answered_at':'2026-10-21T17:45:00Z'})
check('A inserts own attempt',code in (200,201))
retry_code,retry_data=req('POST','/rest/v1/attempts?on_conflict=id',ta,{'id':ia,'user_id':ua,'question_id':qa,'question_version_id':va,'result':'correct','answered_at':'2026-10-21T17:45:00Z'})
check('Duplicate attempt is idempotent',retry_code in (200,201) and retry_data==[])
if code not in (200,201):print('attempt_error',code,str(data)[:300])
code,data=req('GET',f'/rest/v1/attempts?id=eq.{ia}&select=id',tb)
check('B cannot see A attempt',code==200 and data==[])
code,data=req('POST','/rest/v1/attempts',tb,{'id':ib,'user_id':ua,'question_id':qa,'question_version_id':va,'result':'correct','answered_at':'2026-10-21T17:45:00Z'})
check('B cannot insert as A',code in (401,403))
code,data=req('POST','/rest/v1/attempts',tb,{'id':str(uuid.uuid4()),'user_id':ub,'question_id':qa,'question_version_id':va,'result':'correct','answered_at':'2026-10-21T17:45:00Z'})
check('B cannot insert own attempt against private A question',code in (401,403))
code,data=req('GET',f'/rest/v1/attempts?id=eq.{ia}&select=id',ta)
check('A sees own attempt',code==200 and len(data)==1)
print('TOTAL',sum(ok for _,ok in checks),'/',len(checks))
# No delete RLS policy on attempts: preserve fixture IDs for targeted admin cleanup later.
pathlib.Path('/tmp/botai_live_rls_fixture_ids.json').write_text(json.dumps({'user_a':ua,'user_b':ub,'question':qa,'version':va,'attempt':ia}))

if not all(ok for _,ok in checks):
 raise SystemExit(1)
