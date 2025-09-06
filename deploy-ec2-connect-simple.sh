#!/bin/bash

# Simple One-Command Deployment for CampsHub360 using AWS EC2 Instance Connect
# Usage: ./deploy-ec2-connect-simple.sh your-ec2-ip [your-instance-id]

set -e

# Get EC2 IP and Instance ID from command line arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <ec2-ip-address> [instance-id]"
    echo "Example: $0 54.123.45.67 i-1234567890abcdef0"
    exit 1
fi

EC2_INSTANCE_IP="$1"
EC2_INSTANCE_ID="$2"

echo "🚀 Starting CampsHub360 deployment to EC2 using Instance Connect: $EC2_INSTANCE_IP"

# Set environment variables for the EC2 Instance Connect deployment script
export EC2_INSTANCE_IP="$EC2_INSTANCE_IP"
if [ -n "$EC2_INSTANCE_ID" ]; then
    export EC2_INSTANCE_ID="$EC2_INSTANCE_ID"
    echo "📋 Using Instance ID: $EC2_INSTANCE_ID"
fi

# Run the EC2 Instance Connect deployment
./deploy-ec2-connect.sh

echo ""
echo "✅ Deployment completed using AWS EC2 Instance Connect!"
echo "🌐 Your application is now running at: http://$EC2_INSTANCE_IP"
echo "👤 Admin login: admin / admin123"
echo "🔍 Health check: http://$EC2_INSTANCE_IP/health/"
echo ""
echo "💡 To connect to your instance:"
if [ -n "$EC2_INSTANCE_ID" ]; then
    echo "   AWS CLI: aws ssm start-session --target $EC2_INSTANCE_ID --document-name AWS-StartSSHSession"
    echo "   AWS Console: EC2 → Instances → Select instance → Connect → EC2 Instance Connect"
else
    echo "   SSH: ssh ubuntu@$EC2_INSTANCE_IP"
fi
