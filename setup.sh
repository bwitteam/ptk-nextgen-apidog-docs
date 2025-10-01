#!/bin/bash

# Automated setup script for apidog-docs repository
# Project: ptk-microservices
# Project ID: 1083484

set -e

echo "════════════════════════════════════════════════════════"
echo "  🚀 Apidog Docs Setup Script"
echo "  📦 Project: ptk-microservices"
echo "  🆔 Project ID: 1083484"
echo "════════════════════════════════════════════════════════"
echo ""

# Check if already in a directory
if [ -d ".git" ]; then
    echo "⚠️  Warning: Already in a git repository!"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📁 Creating directory structure..."

# Create main directories
mkdir -p services/notification-service/{environments,examples}
mkdir -p scripts
mkdir -p .github/workflows

echo "✅ Directories created"
echo ""

# ========================================
# Create OpenAPI Spec
# ========================================

echo "📝 Creating OpenAPI specification..."

cat > services/notification-service/openapi.yaml << 'EOF'
openapi: 3.1.0
info:
  title: Notification Service API
  version: 1.0.0
  description: Multi-channel notification delivery (Email, WhatsApp, SMS)

servers:
  - url: https://api-dev.ptk.com
    description: Development
  - url: https://api-staging.ptk.com
    description: Staging
  - url: https://api.ptk.com
    description: Production

tags:
  - name: Email
  - name: WhatsApp
  - name: Status

paths:
  /api/v1/notifications/email:
    post:
      summary: Send Email Notification
      tags: [Email]
      security:
        - ApiKeyAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/EmailNotification'
      responses:
        '202':
          description: Accepted
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/NotificationResponse'

  /api/v1/notifications/whatsapp:
    post:
      summary: Send WhatsApp Message
      tags: [WhatsApp]
      security:
        - ApiKeyAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/WhatsAppNotification'
      responses:
        '202':
          description: Accepted

  /api/v1/notifications/{id}:
    get:
      summary: Get Notification Status
      tags: [Status]
      security:
        - ApiKeyAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
      responses:
        '200':
          description: Success

components:
  securitySchemes:
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
  
  schemas:
    EmailNotification:
      type: object
      required: [recipient, subject]
      properties:
        recipient:
          type: string
          format: email
        subject:
          type: string
        content:
          type: string
    
    WhatsAppNotification:
      type: object
      required: [recipient, template_id]
      properties:
        recipient:
          type: string
        template_id:
          type: string
    
    NotificationResponse:
      type: object
      properties:
        id:
          type: integer
        status:
          type: string
        celery_task_id:
          type: string
EOF

echo "✅ OpenAPI spec created"

# ========================================
# Create Environment Files
# ========================================

echo "📝 Creating environment files..."

cat > services/notification-service/environments/dev.json << 'EOF'
{
  "name": "Development",
  "base_url": "https://api-dev.ptk.com",
  "variables": {
    "api_key": "sk_dev_test_key",
    "test_email": "test@example.com"
  }
}
EOF

cat > services/notification-service/environments/production.json << 'EOF'
{
  "name": "Production",
  "base_url": "https://api.ptk.com",
  "variables": {
    "api_key": "{{PROD_API_KEY}}",
    "test_email": "{{TEST_EMAIL}}"
  }
}
EOF

echo "✅ Environment files created"

# ========================================
# Create Example Files
# ========================================

echo "📝 Creating example files..."

cat > services/notification-service/examples/email-request.json << 'EOF'
{
  "recipient": "user@example.com",
  "subject": "Welcome to PTK!",
  "content": "<h1>Welcome!</h1><p>Thank you for joining us.</p>"
}
EOF

cat > services/notification-service/examples/whatsapp-request.json << 'EOF'
{
  "recipient": "+919876543210",
  "template_id": "welcome_message",
  "template_data": {
    "name": "John Doe"
  }
}
EOF

echo "✅ Example files created"

# ========================================
# Create Sync Script
# ========================================

echo "📝 Creating sync script..."

cat > scripts/sync_to_apidog.py << 'EOF'
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
EOF

chmod +x scripts/sync_to_apidog.py

echo "✅ Sync script created"

# ========================================
# Create GitHub Workflow - Copy the complete workflow from previous artifact
# ========================================

echo "📝 Creating GitHub Actions workflow..."

cat > .github/workflows/sync-apidog.yml << 'EOF'
name: Sync to Apidog

on:
  push:
    branches: [main, master]
    paths: ['services/**/openapi.yaml']
  pull_request:
    branches: [main, master]
  workflow_dispatch:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install -g @apidevtools/swagger-cli
      - run: |
          for spec in services/*/openapi.yaml; do
            swagger-cli validate "$spec"
          done

  sync:
    runs-on: ubuntu-latest
    needs: validate
    if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: pip install pyyaml requests
      - env:
          APIDOG_TOKEN: ${{ secrets.APIDOG_TOKEN }}
          APIDOG_PROJECT_ID: ${{ secrets.APIDOG_PROJECT_ID }}
        run: python scripts/sync_to_apidog.py
EOF

echo "✅ GitHub workflow created"

# ========================================
# Create README
# ========================================

echo "📝 Creating README..."

cat > README.md << 'EOF'
# PTK Microservices - API Documentation

Centralized API documentation for all PTK microservices.

## 🎯 Apidog Project

**Project:** ptk-microservices  
**Project ID:** 1083484  
**View:** https://apidog.com/project/1083484

## 📦 Services

- **Notification Service** v1.0.0 - Multi-channel notifications

## 🚀 Quick Start

### View in Apidog
Open Apidog app → Project: ptk-microservices

### Add New Service
```bash
mkdir -p services/my-service/{environments,examples}
touch services/my-service/openapi.yaml
# Edit openapi.yaml
git add . && git commit -m "Add my-service" && git push
```

## 🔄 Auto-Sync

Every push to main automatically syncs to Apidog!

## 📖 Documentation

- OpenAPI specs: `services/*/openapi.yaml`
- Environments: `services/*/environments/*.json`
- Examples: `services/*/examples/*.json`
EOF

echo "✅ README created"

# ========================================
# Create .gitignore
# ========================================

cat > .gitignore << 'EOF'
__pycache__/
*.pyc
.venv/
venv/
.env
.DS_Store
*.swp
EOF

echo "✅ .gitignore created"

# ========================================
# Initialize Git
# ========================================

echo ""
echo "🔧 Initializing git repository..."

git init
git add .
git commit -m "Initial commit: PTK Microservices API documentation

- Notification Service OpenAPI spec
- Environment configurations
- Auto-sync to Apidog (project: 1083484)
- GitHub Actions workflow
"

echo "✅ Git repository initialized"
echo ""

# ========================================
# Print Setup Instructions
# ========================================

echo "════════════════════════════════════════════════════════"
echo "  ✅ Setup Complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1️⃣  Create GitHub repository:"
echo "   gh repo create ptk-apidog-docs --public"
echo "   (or create manually on github.com)"
echo ""
echo "2️⃣  Add GitHub Secrets:"
echo "   Go to: Settings → Secrets → Actions"
echo "   Add: APIDOG_TOKEN = APS-tSdQtiZzvlxADGl620R700T8xse3uwQn"
echo "   Add: APIDOG_PROJECT_ID = 1083484"
echo ""
echo "3️⃣  Push to GitHub:"
echo "   git remote add origin <your-repo-url>"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "4️⃣  Test sync:"
echo "   python scripts/sync_to_apidog.py"
echo ""
echo "════════════════════════════════════════════════════════"
echo "🌐 Your Apidog Project:"
echo "   https://apidog.com/project/1083484"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🎉 All done! Your API documentation is ready to sync."
echo ""
