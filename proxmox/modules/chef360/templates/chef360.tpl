#!/bin/bash

# Chef 360 Installation Script with Logging
LOG_FILE="/home/ubuntu/chef-360-install.log"
ERROR_LOG="/home/ubuntu/chef-360-error.log"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
}

# Start logging
log "=== Chef 360 Installation Started ==="
log "Template variables:"
log "  chef360_channel: ${chef360_channel}"
log "  replicated_key: [REDACTED]"  # Just show it's redacted for security

# This to capture whatever the created default linux user (i.e. ubuntu, ec2-user, etc)
#  assumes there is only one user created during build
default_user=$(ls /home | head -1)
log "Detected default user: $default_user"

# Create log directory if it doesn't exist
sudo mkdir -p /var/log/chef360
sudo chown $default_user:$default_user /var/log/chef360

# Symlink logs to /var/log for easier access
sudo ln -sf "$LOG_FILE" /var/log/chef360/install.log
sudo ln -sf "$ERROR_LOG" /var/log/chef360/error.log

# Download Chef-360
log "Changing to user home directory: /home/$default_user/"
cd /home/$default_user/

log "Starting Chef 360 download..."
log "Download URL: https://replicated.app/embedded/chef-360/${chef360_channel}"

if curl -v https://replicated.app/embedded/chef-360/${chef360_channel} \
    -H "Authorization: ${replicated_key}" \
    -o chef-360-${chef360_channel}.tgz \
    >> "$LOG_FILE" 2>&1; then
    log "Download completed successfully"
    
    # Check if file was actually downloaded
    if [ -f "chef-360-${chef360_channel}.tgz" ]; then
        file_size=$(ls -lh chef-360-${chef360_channel}.tgz | awk '{print $5}')
        log "Downloaded file size: $file_size"
    else
        log_error "Download file not found after curl command"
        exit 1
    fi
else
    log_error "Failed to download Chef 360 package"
    log_error "Curl exit code: $?"
    exit 1
fi

log "Extracting Chef 360 package..."
if tar -xzC /home/$default_user/ -f chef-360-${chef360_channel}.tgz >> "$LOG_FILE" 2>&1; then
    log "Extraction completed successfully"
    
    # List extracted contents
    log "Extracted contents:"
    ls -la /home/$default_user/ | grep chef >> "$LOG_FILE"
else
    log_error "Failed to extract Chef 360 package"
    log_error "Tar exit code: $?"
    exit 1
fi

log "Waiting 120 seconds for system to stabilize..."
sleep 120

# Check if license file exists
if [ ! -f "/home/$default_user/license.yaml" ]; then
    log_error "License file not found at /home/$default_user/license.yaml"
    log "Creating placeholder license file..."
    echo "# Placeholder license file" > /home/$default_user/license.yaml
fi

# Retry Chef 360 installation until it succeeds
max_attempts=8
attempt=1
install_success=false

log "Starting Chef 360 installation with retry logic..."
log "Maximum attempts: $max_attempts"

while [ $attempt -le $max_attempts ] && [ "$install_success" = false ]; do
    log "=== Installation Attempt $attempt of $max_attempts ==="
    
    # Check if chef-360 binary exists
    if [ ! -f "/home/$default_user/chef-360" ]; then
        log_error "Chef 360 binary not found at /home/$default_user/chef-360"
        ls -la /home/$default_user/ >> "$LOG_FILE"
        exit 1
    fi
    
    # Make sure the binary is executable
    chmod +x /home/$default_user/chef-360
    
    log "Running: sudo /home/$default_user/chef-360 install --license license.yaml --no-prompt"
    
    if sudo /home/$default_user/chef-360 install --license license.yaml --no-prompt >> "$LOG_FILE" 2>&1; then
        log "✅ Chef 360 installation successful on attempt $attempt"
        install_success=true
        
        # Check if services are running
        log "Checking Chef 360 services..."
        sudo systemctl status chef-360 >> "$LOG_FILE" 2>&1 || true
        
        # Check if ports are listening
        log "Checking listening ports..."
        sudo netstat -tlnp | grep -E "(30000|31000|31101)" >> "$LOG_FILE" 2>&1 || true
        
    else
        log_error "❌ Chef 360 installation failed on attempt $attempt"
        log_error "Installation exit code: $?"
        
        # Capture additional debugging info
        log "System resources at failure:"
        df -h >> "$LOG_FILE" 2>&1
        free -h >> "$LOG_FILE" 2>&1
        
        # Check system logs for errors
        log "Recent system errors:"
        sudo journalctl --since "5 minutes ago" --priority=err >> "$LOG_FILE" 2>&1 || true
        
        if [ $attempt -lt $max_attempts ]; then
            log "Waiting 60 seconds before retry..."
            sleep 60
        fi
    fi
    
    attempt=$((attempt + 1))
done

if [ "$install_success" = false ]; then
    log_error "🚨 Chef 360 installation failed after $max_attempts attempts"
    log_error "Check logs at:"
    log_error "  - $LOG_FILE"
    log_error "  - $ERROR_LOG"
    log_error "  - /var/log/chef360/"
    exit 1
fi

log "🎉 Chef 360 installation completed successfully!"
log "Installation summary:"
log "  - Installation attempts: $((attempt - 1))"
log "  - Log file: $LOG_FILE"
log "  - Error log: $ERROR_LOG"
log "  - Symlinked logs: /var/log/chef360/"
log ""
log "=== Chef 360 Installation Finished ==="

# Final system check
log "Final system status:"
sudo systemctl status chef-360 >> "$LOG_FILE" 2>&1 || true
sudo netstat -tlnp | grep -E "(30000|31000|31101)" >> "$LOG_FILE" 2>&1 || true