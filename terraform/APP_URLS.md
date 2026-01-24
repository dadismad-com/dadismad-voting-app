# Getting Application URLs

After deploying your voting app to GKE via GitHub Actions, you can easily get the LoadBalancer URLs for accessing the Vote and Result applications.

## 🚀 Quick Method

```bash
cd terraform
./get-urls.sh
```

This will check for deployed services and display the URLs.

## 📋 Manual Methods

### Method 1: Terraform Outputs

```bash
# Enable service checking
terraform apply -var='check_services=true'

# View URLs
terraform output vote_app_url
terraform output result_app_url
```

### Method 2: Using kubectl

```bash
# Get cluster credentials
gcloud container clusters get-credentials dadismad-cluster-1 --zone us-central1-a

# Get LoadBalancer IPs
kubectl get svc vote-lb result-lb

# Get specific URLs
echo "Vote App: http://$(kubectl get svc vote-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "Result App: http://$(kubectl get svc result-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
```

## 🔍 What the check_services Variable Does

By default, Terraform doesn't check for Kubernetes LoadBalancer services to avoid errors when they haven't been deployed yet.

- **`check_services=false` (default)**: Terraform won't query Kubernetes services
- **`check_services=true`**: Terraform will read LoadBalancer IPs and show URLs

## ⏱️ When to Use

1. **First time**: Deploy infrastructure with `terraform apply` (check_services=false by default)
2. **Deploy app**: Use GitHub Actions to deploy the application
3. **Get URLs**: Run `./get-urls.sh` or `terraform apply -var='check_services=true'`
4. **Updates**: After any deployment, re-run to get updated IPs

## 📝 Expected Outputs

### Before Deployment
```
vote_app_url = "Not checked - set check_services=true and run: terraform apply -var='check_services=true'"
result_app_url = "Not checked - set check_services=true and run: terraform apply -var='check_services=true'"
```

### LoadBalancers Pending
```
vote_app_url = "<pending>"
result_app_url = "<pending>"
```

### After Successful Deployment
```
vote_app_url = "http://34.135.45.67"
result_app_url = "http://34.135.45.89"
```

## 🛠️ Troubleshooting

### Services Not Found
**Error:** `Error reading Service...`

**Solution:** Deploy the application via GitHub Actions first:
```bash
gh workflow run deploy-to-gke.yaml --ref main
```

### LoadBalancer Pending
**Issue:** URLs show `<pending>`

**Solution:** LoadBalancers take 2-5 minutes to provision. Wait and run `./get-urls.sh` again.

### Permission Denied
**Error:** `Error getting credentials...`

**Solution:** Authenticate to GCP:
```bash
gcloud auth application-default login
```

## 🔗 Related Files

- `get-urls.sh` - Helper script to get URLs
- `main.tf` - Kubernetes provider configuration
- `outputs.tf` - URL output definitions
- `variables.tf` - `check_services` variable
- `README.md` - Full Terraform documentation

## 💡 Tips

1. **Bookmark URLs**: Once deployed, IPs rarely change unless you destroy LoadBalancers
2. **Check after deployments**: Run `./get-urls.sh` after each GitHub Actions deployment
3. **Use in scripts**: Get raw IPs with `terraform output -raw vote_ip`
4. **Monitor status**: Watch deployment with `kubectl get svc -w`

---

**Quick Access:**
```bash
# One-liner to open Vote app
open $(cd terraform && terraform output -raw vote_app_url 2>/dev/null)

# One-liner to open Result app
open $(cd terraform && terraform output -raw result_app_url 2>/dev/null)
```
