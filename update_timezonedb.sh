#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root."
  exit 1
fi

echo "=================================================="
echo " Starting TimezoneDB Update for Installed PHP Versions"
echo "=================================================="

# Loop through all PHP directories matching /usr/local/php*
for php_dir in /usr/local/php*; do
  # Check if directory and PECL executable exist
  if [ -d "$php_dir" ] && [ -x "$php_dir/bin/pecl" ]; then
    
    php_version_name=$(basename "$php_dir") # e.g., php74 or php83
    fpm_suffix="${php_version_name#php}"   # e.g., 74 or 83
    
    echo ""
    echo "--------------------------------------------------"
    echo " Processing: ${php_version_name}"
    echo "--------------------------------------------------"

    # 1. Upgrade or Force Install timezonedb
    echo "[1/5] Installing/Upgrading timezonedb..."
    "$php_dir/bin/pecl" upgrade timezonedb
    if [ $? -ne 0 ]; then
      echo "Upgrade failed or not available. Trying forced installation..."
      "$php_dir/bin/pecl" install -f timezonedb
    fi

    # 2. Set permissions (chmod 0755) for timezonedb.so
    echo "[2/5] Setting permissions for timezonedb.so..."
    ext_dir=$("$php_dir/bin/php-config" --extension-dir 2>/dev/null)
    if [ -f "$ext_dir/timezonedb.so" ]; then
      chmod 0755 "$ext_dir/timezonedb.so"
      echo "Permissions set to 0755 for: $ext_dir/timezonedb.so"
    else
      echo "Warning: Could not find timezonedb.so in $ext_dir to set permissions."
    fi

    # 3. Add extension directive if not already present
    ini_file="$php_dir/lib/php.conf.d/10-directadmin.ini"
    echo "[3/5] Configuring INI file: ${ini_file}"
    
    # Ensure directory exists
    mkdir -p "$(dirname "$ini_file")"

    if [ -f "$ini_file" ] && grep -q "extension=timezonedb.so" "$ini_file"; then
      echo "Notice: 'extension=timezonedb.so' is already present in ${ini_file}."
    else
      echo "extension=timezonedb.so" >> "$ini_file"
      echo "Added 'extension=timezonedb.so' to ${ini_file}."
    fi

    # 4. Restart PHP-FPM service
    fpm_service="php-fpm${fpm_suffix}"
    echo "[4/5] Restarting service: ${fpm_service}..."
    if systemctl is-active --quiet "$fpm_service" || systemctl list-unit-files | grep -q "${fpm_service}.service"; then
      systemctl restart "$fpm_service"
      echo "Service ${fpm_service} restarted successfully."
    else
      echo "Warning: Service ${fpm_service} was not found or is not active. Skipping restart."
    fi

    # 5. Verify installation
    echo "[5/5] Verification Test for ${php_version_name}:"
    "$php_dir/bin/php" -r "echo '  Time: ' . date('Y-m-d H:i:s T') . PHP_EOL . '  Timezone: ' . date_default_timezone_get() . PHP_EOL . '  TimezoneDB: ' . timezone_version_get() . PHP_EOL;"

  fi
done

echo ""
echo "=================================================="
echo " TimezoneDB update process completed!"
echo "=================================================="
