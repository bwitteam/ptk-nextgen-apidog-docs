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
