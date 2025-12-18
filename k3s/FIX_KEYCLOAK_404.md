# Fix for Keycloak /auth/realms 404 Error

## Problem

When accessing Keycloak endpoints like `/auth/realms`, you may encounter a "Page not found" error with the message:
```
We are sorry...
Page not found
```

## Root Cause

Keycloak version 20.0.2 uses Quarkus and changed its URL structure:
- **Old Keycloak (< 17)**: Used `/auth/` prefix for all endpoints
  - Admin console: `/auth/admin`
  - Realms: `/auth/realms/{realm-name}`

- **New Keycloak (17+)**: Removed the `/auth/` prefix
  - Admin console: `/admin`
  - Realms: `/realms/{realm-name}`

## Solution

The nginx configuration has already been updated with a URL rewrite rule to strip the `/auth` prefix before proxying to Keycloak. However, you need to update the ConfigMap in your k3s cluster.

### Step 1: Update the ConfigMap

Run the ConfigMap creation script to update the nginx configuration:

```bash
cd k3s/scripts
./00-create-configmaps.sh
```

This script will:
1. Delete the existing `apigateway-configmap`
2. Create a new `apigateway-configmap` with the updated nginx.conf
3. The updated configuration includes the rewrite rule: `rewrite /auth/(.*) /$1 break;`

### Step 2: Restart the API Gateway

After updating the ConfigMap, restart the API Gateway deployment to pick up the changes:

```bash
kubectl rollout restart deployment/apigateway-deployment -n vinlab
```

Or if you don't have kubectl access, use k3s kubectl:

```bash
k3s kubectl rollout restart deployment/apigateway-deployment -n vinlab
```

### Step 3: Verify the Fix

Wait for the pod to restart (about 30-60 seconds), then verify:

```bash
kubectl get pods -n vinlab | grep apigateway
```

The pod should show `Running` status with `1/1` ready.

### Step 4: Test Keycloak Access

Test the following URLs:
- Admin console: `http://localhost:30080/auth/admin` (or your server IP)
- Realms endpoint: `http://localhost:30080/auth/realms/master`

Both should now work correctly without 404 errors.

## What the Fix Does

The nginx configuration now includes this location block (lines 82-103 in nginx.conf):

```nginx
location /auth {
    if ($request_method = 'OPTIONS') {
        # CORS handling
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow_Credentials' 'true';
        add_header 'Access-Control-Allow-Headers' 'Authorization,Accept,Origin,DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range';
        add_header 'Access-Control-Allow-Methods' 'GET,POST,OPTIONS,PUT,DELETE,PATCH';
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain charset=UTF-8';
        add_header 'Content-Length' 0;
        return 204;
    }
    rewrite /auth/(.*) /$1 break;  # This line strips the /auth prefix
    proxy_set_header Host $http_host;
    proxy_pass http://keycloak.vinlab:8080;
    proxy_set_header X-Real-IP          $remote_addr;
    proxy_set_header X-Forwarded-For    $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto  $scheme;
    add_header 'Access-Control-Allow-Credentials' 'true';
    add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    add_header 'Access-Control-Allow-Origin' '*';
}
```

The key line is `rewrite /auth/(.*) /$1 break;` which:
- Matches any URL starting with `/auth/`
- Strips the `/auth/` prefix
- Forwards the rest of the path to Keycloak

Example transformations:
- `/auth/admin` → `/admin` (sent to Keycloak)
- `/auth/realms/master` → `/realms/master` (sent to Keycloak)
- `/auth/realms/vinlab/protocol/openid-connect/token` → `/realms/vinlab/protocol/openid-connect/token`

## Troubleshooting

If the issue persists after following these steps:

1. **Check ConfigMap was updated:**
   ```bash
   kubectl get configmap apigateway-configmap -n vinlab -o yaml | grep "rewrite /auth"
   ```
   You should see the rewrite rule in the output.

2. **Check API Gateway pod logs:**
   ```bash
   kubectl logs -n vinlab -l app=apigateway
   ```
   Look for nginx configuration errors.

3. **Verify Keycloak is running:**
   ```bash
   kubectl get pods -n vinlab | grep keycloak
   ```
   The Keycloak pod should be running.

4. **Test direct access to Keycloak:**
   ```bash
   kubectl port-forward -n vinlab svc/keycloak 8080:8080
   ```
   Then access `http://localhost:8080/realms/master` directly (without `/auth` prefix).

## Additional Notes

- This fix applies to the k3s deployment. The same fix has been applied to the Docker and Kubernetes deployments in their respective nginx configurations.
- The fix was implemented in commit `b4cc3a2` on 2025-12-18.
- If you're using Docker deployment, the fix is already included in `docker/conf/nginx/nginx.conf`.
- If you're using the old Kubernetes deployment, the fix is in `kubernetes/vinlab-configmap/nginx.conf`.

## Related Endpoints

After applying the fix, all Keycloak endpoints will work correctly:
- Admin Console: `/auth/admin`
- Master Realm: `/auth/realms/master`
- Custom Realm: `/auth/realms/{your-realm-name}`
- Token Endpoint: `/auth/realms/{realm}/protocol/openid-connect/token`
- User Info: `/auth/realms/{realm}/protocol/openid-connect/userinfo`

---

**Have fun! 🍪**
