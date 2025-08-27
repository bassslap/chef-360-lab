# Chef 360 Proxmox - Post Provisioning Installation Instructions

## Validate the Provisioning

The first thing to do is verify all VMs are running and accessible.

### Check VM Status in Proxmox

1. **Access Proxmox Web Interface**
   - Go to `https://your-proxmox-host:8006`
   - Check that all VMs are running (green status)

2. **Verify Network Connectivity**
   ```bash
   # From the Proxmox host, check VM IPs
   qm list
   
   # Test connectivity to Chef 360 VM
   ping <chef360-ip>
   
   # Test connectivity to workstation
   ping <workstation-ip>
   ```

### SSH Access Test

```bash
# SSH to workstation (replace with actual IP from terraform output)
ssh -i ~/.ssh/your-key ubuntu@<workstation-ip>

# From workstation, SSH to Chef 360 server
ssh -i ~/.ssh/your-key ubuntu@<chef360-ip>

# Check Chef 360 installation progress
tail -f /home/ubuntu/chef-360-install.log
```

You should see log entries showing the Chef 360 installation progress. The final message should be:
```
Visit the admin console to configure and install chef-360: http://<chef360-ip>:30000
```

This could take 15-20 minutes after VM provisioning completes.

### Quick Connectivity Test

```bash
# Test if Chef 360 admin console is responding
curl http://<chef360-ip>:30000
```

## Configure and Install Chef 360 with Replicated

> NOTE: These instructions are for **RC** and **GA** versions

### Initial Setup

1. **Access Chef 360 Admin Console**
   - Go to `http://<chef360-ip>:30000` (use IP from terraform output)
   - On the "Not secure" webpage, click `Continue to Setup`
   - Click `Show Advanced` and `Continue to [IP] (unsafe)`

2. **Upload SSL Certificates**
   - On the **HTTPS for the Chef 360 admin console** page
   - Select `Upload your own` Certificate Type
   - **Use the actual VM IP address** instead of FQDN
   - Click `Choose private key` and select the `.key.pem` file from `./tmp/`
   - Click `Choose SSL certificate` and select the `.chain.pem` file from `./tmp/`
   - Click `Upload and Continue`

   > Note: The exact filenames are shown in the `SSL_Certificate_Files` terraform output

3. **Login to Replicated Console**
   - Default password is "password" (since we used `--no-prompt` install)

### Chef 360 Configuration

1. **Basic Settings**
   - For the tenant, use `primary` (first tenant space)  
   - The tenant TLD (Top Level Domain): use `local.lab` or similar
   - The subdomain: use your `dns_shortname` from terraform.tfvars
   - **Important**: Set the endpoint URL to the actual VM IP and port: `http://192.168.1.100:31000`

   > TIP: Use the actual IP address from terraform outputs, not the FQDN

2. **SMTP Configuration**
   - Select `Mailpit` for SMTP (built-in development SMTP)

3. **Tenant Administrator**
   - Add your email and admin information
   - You will **NOT** get an email - check Mailpit instead

4. **Primary Tenant Org Unit**
   - Set as `default`, `prod`, `dev`, or your preference
   - This is like Orgs in Chef Infra Server

5. **API/UI Settings**
   - Leave ports as default
   - **GATEWAY CERT METHOD** is important for Proxmox deployment
   - Select `Custom Certificate` and upload the same files as above:
     - Private Key: `./tmp/<your-fqdn>.key.pem`
     - Certificate: `./tmp/<your-fqdn>.chain.pem`
     - Leave Certificate Root Cert blank

6. **Deploy Chef 360**
   - RabbitMQ settings can stay default
   - Click `Continue` to build
   - Run pre-flight checks
   - Click `Deploy`

## Log into Chef 360 (Platform)

### Check Mailpit for Credentials

1. **Access Mailpit**
   ```bash
   # Go to Mailpit web interface
   open http://<chef360-ip>:31101/
   ```

2. **Retrieve Password Reset Link**
   - You should see 2 messages: Welcome and `Set Password`
   - Open the `Set Password` email
   - Copy the password reset link (similar to):
     ```
     https://<chef360-ip>:31000/platform/user-accounts/v1/identity/email/admin@example.com/password/set?otp=866538
     ```

3. **Set Your Password**
   - Paste the link in your browser
   - Create a new password
   - **Note**: You have 5 minutes to complete this step

4. **Access Chef 360 Platform**
   - Login at `https://<chef360-ip>:31000/app/`
   - Use your email and the password you just set
   - Select your Org and role

## Workstation Configuration / Device Registration

### Download Chef 360 CLI Tools

1. **Access CLI Download Page**
   - Log into Chef 360 Replicated Configuration UI
   - Click the "Download CLIs" link, or go to:
     ```
     https://<chef360-ip>:31000/platform/bundledtools/v1/static/index.html
     ```

2. **Download for Your Platform**
   - Select Linux (for the workstation VM)
   - Download and run the installation script

### Register the Workstation Device

This registers the workstation as an approved system for Chef 360 interaction:

```bash
# From the workstation VM
./chef-platform-auth-cli register-device \
  --url https://<chef360-ip>:31000 \
  --profile-name platform-default
```

1. **Follow the Registration Link**
   - You'll get a link to click
   - Open it in a browser
   - Log in with your email and password
   - Approve the registration
   - Select "Doesn't Expire" for demos

2. **Complete Registration**
   - Back in the CLI, hit `y` to complete
   - You should see `Device registered successfully`

### Test Authentication

```bash
# List profiles
chef-platform-auth-cli list-profile-names

# View credentials
cat ~/.chef-platform/credentials

# Test connection
chef-platform-auth-cli user-account self get-role
```

## Bringing a Node under Management

Once workstation is registered, you can start managing the Linux/Windows nodes that were created during the Terraform deployment.

### Access Node VMs

```bash
# SSH to Linux nodes (replace with IPs from terraform output)
ssh -i ~/.ssh/your-key ubuntu@<node-linux-01-ip>
ssh -i ~/.ssh/your-key ubuntu@<node-linux-02-ip>
```

### Node Management

Follow the standard Chef 360 node management procedures using the CLI tools installed on the workstation.

## Network Considerations for Proxmox

### Internal Network Access

- All VMs are on the same network bridge (`vmbr0` by default)
- VMs get DHCP IPs from your network
- If using VLANs, ensure proper VLAN configuration

### External Access

- Configure port forwarding or firewall rules as needed
- For production, consider setting up a reverse proxy
- Ensure DNS resolution for your chosen FQDN

### SSL Certificates

- The deployment uses self-signed certificates
- For production, consider:
  - Using a proper CA-signed certificate
  - Setting up Let's Encrypt with DNS challenge
  - Configuring a reverse proxy with proper SSL

## Troubleshooting

### VM Issues

```bash
# Check VM status in Proxmox
qm status <vmid>

# View VM logs
qm log <vmid>

# Console access
qm monitor <vmid>
```

### Chef 360 Installation Issues

```bash
# SSH to Chef 360 VM
ssh ubuntu@<chef360-ip>

# Check installation logs
tail -f /home/ubuntu/chef-360-install.log

# Check if services are running
sudo systemctl status docker
sudo docker ps
```

### Network Connectivity

```bash
# Test from Proxmox host
ping <vm-ip>
telnet <chef360-ip> 30000
telnet <chef360-ip> 31000

# Test from workstation
curl http://<chef360-ip>:30000
curl http://<chef360-ip>:31000
```

## Next Steps

1. **Explore Chef 360**: Navigate the web interface and familiarize yourself with the platform
2. **Import Nodes**: Use the workstation to bring your infrastructure under Chef 360 management
3. **Create Skills**: Develop automation using Chef 360's skill system
4. **Set up Monitoring**: Configure monitoring and alerting for your environment

## Production Considerations

### Security
- Change default passwords
- Use proper SSL certificates
- Configure firewalls appropriately
- Regular security updates

### Networking
- Use static IP addresses for production
- Configure proper DNS records
- Set up load balancing if needed
- Consider network segmentation

### Backup
- Regular VM snapshots
- Backup Chef 360 configuration
- Document your setup procedures

### Scaling
- Monitor resource usage
- Plan for horizontal scaling
- Consider high availability setup

This completes the basic Chef 360 setup on Proxmox. You now have a fully functional Chef 360 environment running on your own virtualization infrastructure!
