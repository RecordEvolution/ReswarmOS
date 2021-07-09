
import json

with open('config/supported-boards.json','r') as fin:
    raw = fin.read()
    boards = json.loads(raw)

print(json.dumps(boards,indent=2,sort_keys=False))
print(boards['boards'][1])
print(boards['boards'][1]['latest-image'])

