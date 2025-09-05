# CampsHub360 AWS Deployment Guide

## 🚀 **Best Manual Setup Option**

### **Prerequisites**
- AWS EC2 instance running Ubuntu 22.04
- AWS RDS PostgreSQL database
- AWS ElastiCache Redis cluster
- Domain name (optional)

---

## 📋 **Step-by-Step Manual Setup**

### **1. Connect to Your EC2 Instance**
```bash
# Using SSH key
ssh -i your-key.pem ubuntu@35.154.2.91

# Or using AWS EC2 Instance Connect (recommended)
# Go to EC2 Console → Select your instance → Connect → EC2 Instance Connect
```

### **2. Clone Your Repository**
```bash
git clone https://github.com/your-username/campshub360-backend.git
cd campshub360-backend
```

### **3. Make Scripts Executable**
```bash
chmod +x *.sh
```

### **4. Run Initial Setup**
```bash
sudo ./setup_aws_ec2.sh
```
*This installs all system dependencies, configures firewall, and sets up monitoring.*

### **5. Fix RDS Connection (IMPORTANT)**
Before running the deployment, you **MUST** fix the RDS connection:

#### **Option A: Use AWS Console (Recommended)**
1. Go to **RDS Console** → **Databases** → Select `database-1`
2. Click **"Actions"** → **"Set up EC2 connection"**
3. Select your EC2 instance
4. Click **"Set up connection"**
5. Wait 2-3 minutes for changes to apply

#### **Option B: Manual Security Group Fix**
1. Go to **RDS Console** → **Databases** → Select `database-1`
2. Click **"Connectivity & security"** tab
3. Click on the **Security group** link
4. Click **"Edit inbound rules"**
5. Add rule:
   - **Type**: PostgreSQL
   - **Port**: 5432
   - **Source**: Custom → Your EC2 Security Group ID

### **6. Fix ElastiCache Connection (IMPORTANT)**
1. Go to **ElastiCache Console** → **Redis clusters** → Select your cluster
2. Click **"Actions"** → **"Modify"**
3. Update security groups to allow EC2 access
4. Wait 2-3 minutes for changes to apply

### **7. Deploy the Application**
```bash
sudo ./deploy.sh
```
*This script handles everything: dependencies, database, Redis, migrations, services, and nginx.*

---

## 🎯 **What the Deploy Script Does**

1. **Creates .env file** with your AWS configuration
2. **Installs all dependencies** (Python, PostgreSQL client, nginx, Redis tools)
3. **Tests AWS connections** (RDS + ElastiCache)
4. **Runs database migrations**
5. **Creates superuser** (admin/admin123)
6. **Collects static files**
7. **Sets up systemd service**
8. **Configures nginx**
9. **Starts all services**
10. **Runs health checks**

---

## 🌐 **Access Your Application**

After successful deployment:

- **Application**: http://35.154.2.91
- **Admin Panel**: http://35.154.2.91/admin/ (admin/admin123)
- **Health Check**: http://35.154.2.91/health/
- **API**: http://35.154.2.91/api/

---

## 🔧 **Troubleshooting**

### **RDS Connection Failed**
- Check RDS security groups allow connections from EC2
- Verify database credentials in .env file
- Ensure RDS instance is running

### **ElastiCache Connection Failed**
- Check ElastiCache security groups allow connections from EC2
- Verify Redis endpoint in .env file
- Ensure ElastiCache cluster is running

### **Service Not Starting**
```bash
# Check logs
sudo journalctl -u campshub360 -f

# Check service status
sudo systemctl status campshub360
sudo systemctl status nginx
```

### **Application Not Accessible**
```bash
# Test locally
curl http://localhost:8000/health/

# Test publicly
curl http://35.154.2.91/health/
```

---

## 📝 **Important Notes**

1. **Change Admin Password**: After deployment, change the default admin password
2. **Security Groups**: Ensure RDS and ElastiCache security groups allow connections from EC2
3. **Frontend**: Your frontend at localhost:5173 should be able to connect to the API
4. **Logs**: Check logs with `sudo journalctl -u campshub360 -f`

---

## 🔄 **If You Need to Redeploy**

```bash
# Stop services
sudo systemctl stop campshub360 nginx

# Run deployment again
sudo ./deploy.sh

# Or restart services
sudo systemctl restart campshub360 nginx
```

---

## 🎉 **Success!**

Your CampsHub360 application is now deployed and running on AWS!

**The key is fixing the RDS and ElastiCache security groups BEFORE running the deployment script.**
