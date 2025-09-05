# CampsHub360 AWS Deployment Guide

## Quick Deployment Steps

### 1. Connect to EC2 Instance
```bash
ssh -i your-key.pem ubuntu@35.154.2.91
```

### 2. Clone Repository
```bash
git clone https://github.com/your-username/campshub360-backend.git
cd campshub360-backend
```

### 3. Make Scripts Executable
```bash
chmod +x *.sh
```

### 4. Run Initial Setup
```bash
sudo ./setup_aws_ec2.sh
```

### 5. Setup Environment
```bash
./setup_env.sh
```

### 6. Deploy Application
```bash
sudo ./deploy_aws.sh
```

### 7. Test Deployment
```bash
curl http://35.154.2.91/health/
curl http://35.154.2.91/admin/
```

## Access Points

- **Application**: http://35.154.2.91
- **Admin Panel**: http://35.154.2.91/admin/ (admin/admin123)
- **Health Check**: http://35.154.2.91/health/
- **API**: http://35.154.2.91/api/

## Important Notes

1. **Change Admin Password**: After deployment, change the default admin password
2. **Security Groups**: Ensure RDS and ElastiCache security groups allow connections from EC2
3. **Frontend**: Your frontend at localhost:5173 should be able to connect to the API
4. **Logs**: Check logs with `sudo journalctl -u campshub360 -f`

## Troubleshooting

- **Service not starting**: Check logs with `sudo journalctl -u campshub360 -f`
- **Database connection failed**: Check RDS security groups
- **Redis connection failed**: Check ElastiCache security groups
- **CORS issues**: Verify CORS_ALLOWED_ORIGINS in .env file
