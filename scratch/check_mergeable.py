import urllib.request
import json
import time

cred_path = 'C:/Users/KaueKKL/.gemini/antigravity/brain/47655c93-6910-4e5c-8913-a6daac9eada5/scratch/cred.txt'
token = [l.split('=', 1)[1] for l in open(cred_path, encoding='utf-8').read().splitlines() if l.startswith('password=')][0]

approved_prs = [80, 87, 88, 89, 90, 91, 92, 93, 94]

print(f"Target approved PRs: {approved_prs}")

for num in approved_prs:
    req_get = urllib.request.Request(
        f"https://api.github.com/repos/AdrianRiegel/app_mobile/pulls/{num}",
        headers={'Authorization': f'Bearer {token}', 'User-Agent': 'KaueKKL'}
    )
    p = json.loads(urllib.request.urlopen(req_get).read().decode('utf-8'))
    print(f"PR #{num} ({p['title']}) - State: {p['state']} - Mergeable: {p.get('mergeable')} - MergeableState: {p.get('mergeable_state')}")
