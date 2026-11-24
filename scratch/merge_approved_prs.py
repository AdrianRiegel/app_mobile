import urllib.request
import json
import time

cred_path = 'C:/Users/KaueKKL/.gemini/antigravity/brain/47655c93-6910-4e5c-8913-a6daac9eada5/scratch/cred.txt'
token = [l.split('=', 1)[1] for l in open(cred_path, encoding='utf-8').read().splitlines() if l.startswith('password=')][0]

approved_prs = [80, 90, 88, 92, 87, 89, 91, 93, 94]

results = []

for num in approved_prs:
    # First, get PR details
    req_get = urllib.request.Request(
        f"https://api.github.com/repos/AdrianRiegel/app_mobile/pulls/{num}",
        headers={'Authorization': f'Bearer {token}', 'User-Agent': 'KaueKKL'}
    )
    p = json.loads(urllib.request.urlopen(req_get).read().decode('utf-8'))
    title = p['title']
    
    # Attempt merge
    merge_url = f"https://api.github.com/repos/AdrianRiegel/app_mobile/pulls/{num}/merge"
    payload = {
        'commit_title': f"Merge pull request #{num} from {p['head']['ref']}",
        'merge_method': 'merge'
    }
    
    req_merge = urllib.request.Request(
        merge_url,
        data=json.dumps(payload).encode('utf-8'),
        headers={
            'Authorization': f'Bearer {token}',
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'KaueKKL',
            'Content-Type': 'application/json'
        },
        method='PUT'
    )
    
    try:
        with urllib.request.urlopen(req_merge) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            print(f"SUCCESS: PR #{num} ('{title}') merged: sha={data.get('sha')}")
            results.append((num, title, True, "Merged successfully"))
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode('utf-8')
        print(f"FAILED: PR #{num} ('{title}') HTTP {e.code}: {err_msg}")
        results.append((num, title, False, f"HTTP {e.code}: {err_msg}"))
    except Exception as e:
        print(f"ERROR: PR #{num} ('{title}'): {e}")
        results.append((num, title, False, str(e)))
        
    time.sleep(2) # brief pause for GitHub to update base branch refs

print("\n--- Summary of Merges ---")
for num, title, success, msg in results:
    status = "MERGED" if success else "FAILED"
    print(f"[{status}] PR #{num}: {title} - {msg}")
