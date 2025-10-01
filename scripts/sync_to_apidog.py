#!/usr/bin/env python3
import os, sys, json, yaml, requests
from pathlib import Path

APIDOG_TOKEN = os.getenv("APIDOG_TOKEN", "APS-tSdQtiZzvlxADGl620R700T8xse3uwQn")
APIDOG_PROJECT_ID = os.getenv("APIDOG_PROJECT_ID", "1083484")
APIDOG_API_BASE = "https://api.apidog.com/api/v1"

def load_openapi_spec(service_path):
    with open(service_path / "openapi.yaml", 'r') as f:
        return yaml.safe_load(f)

def sync_to_apidog(service_name, openapi_spec):
    url = f"{APIDOG_API_BASE}/projects/{APIDOG_PROJECT_ID}/import-data"
    headers = {
        "Authorization": f"Bearer {APIDOG_TOKEN}",
        "Content-Type": "application/json"
    }
    payload = {
        "input": {"type": "openapi", "data": openapi_spec},
        "options": {"mode": "merge"}
    }
    
    print(f"📤 Syncing {service_name} to ptk-microservices...")
    response = requests.post(url, headers=headers, json=payload, timeout=60)
    
    if response.status_code in [200, 201]:
        print(f"✅ {service_name} synced successfully!")
        return True
    else:
        print(f"❌ Failed: {response.status_code}")
        print(f"Response: {response.text[:200]}")
        return False

def main():
    print("🚀 Apidog Sync - ptk-microservices (1083484)\n")
    
    services_dir = Path("services")
    services = [d.name for d in services_dir.iterdir() if d.is_dir() and not d.name.startswith('.')]
    
    results = {}
    for service in services:
        service_path = services_dir / service
        try:
            spec = load_openapi_spec(service_path)
            results[service] = sync_to_apidog(service, spec)
        except Exception as e:
            print(f"❌ Error with {service}: {e}")
            results[service] = False
    
    success = sum(results.values())
    print(f"\n✅ Success: {success}/{len(results)}")
    print(f"🌐 View: https://apidog.com/project/1083484")
    
    sys.exit(0 if all(results.values()) else 1)

if __name__ == "__main__":
    main()
