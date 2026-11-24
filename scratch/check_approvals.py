import urllib.request
import json

cred_path = 'C:/Users/KaueKKL/.gemini/antigravity/brain/47655c93-6910-4e5c-8913-a6daac9eada5/scratch/cred.txt'
token = [l.split('=', 1)[1] for l in open(cred_path, encoding='utf-8').read().splitlines() if l.startswith('password=')][0]

req = urllib.request.Request(
    'https://api.github.com/repos/AdrianRiegel/app_mobile/pulls?state=open&per_page=100',
    headers={'Authorization': f'Bearer {token}', 'User-Agent': 'KaueKKL'}
)
prs = json.loads(urllib.request.urlopen(req).read().decode('utf-8'))

print(f"Total open PRs: {len(prs)}")
for p in prs:
    num = p['number']
    req_reviews = urllib.request.Request(
        f"https://api.github.com/repos/AdrianRiegel/app_mobile/pulls/{num}/reviews",
        headers={'Authorization': f'Bearer {token}', 'User-Agent': 'KaueKKL'}
    )
    reviews = json.loads(urllib.request.urlopen(req_reviews).read().decode('utf-8'))
    approvals = [r['user']['login'] for r in reviews if r['state'] == 'APPROVED']
    print(f"PR #{num}: '{p['title']}' by {p['user']['login']} | Approvals: {approvals} | Mergeable: {p.get('mergeable')}")
