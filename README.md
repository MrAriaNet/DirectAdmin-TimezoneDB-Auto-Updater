# DirectAdmin TimezoneDB Auto-Updater

An automated Bash script to compile, install, configure, and verify the PECL `timezonedb` extension across all installed PHP versions on a DirectAdmin server.

## 🚀 Features

- **Auto-Detection:** Automatically scans `/usr/local/php*` to detect all installed PHP versions.
- **Smart Installation:** Attempts `pecl upgrade timezonedb` first, falling back to `pecl install -f` if required.
- **Permission Management:** Sets explicit `0755` permissions on `timezonedb.so` within the extension directory to prevent loading issues.
- **Idempotent Configuration:** Safely adds `extension=timezonedb.so` to `10-directadmin.ini` without creating duplicate entries.
- **Service Management:** Gracefully restarts matching `php-fpm` services (e.g., `php-fpm74`, `php-fpm83`).
- **Post-Install Verification:** Tests each PHP binary and outputs the current date, active timezone, and TimezoneDB version.

---

## 📋 Requirements

- Linux server with DirectAdmin installed.
- Root privileges (`sudo` / `root`).
- PECL utility available for installed PHP versions.

---

## 🛠️ Usage

### 1. Download or Clone
Clone this repository or download the script directly:
```bash
git clone https://github.com/MrAriaNet/DirectAdmin-TimezoneDB-Auto-Updater.git
cd DirectAdmin-TimezoneDB-Auto-Updater

```

### 2. Make Executable

Grant execution permissions to the script:

```bash
chmod +x update_timezonedb.sh

```

### 3. Run the Script

Execute the script with root privileges:

```bash
sudo ./update_timezonedb.sh

```

---

## 🔍 How It Works

For every detected directory matching `/usr/local/php*`, the script performs the following steps:

1. **Build & Upgrade:** Executes PECL upgrade/install.
2. **Set Permissions:** Retrieves the PHP extension directory path dynamically via `php-config --extension-dir` and applies `chmod 0755` on `timezonedb.so`.
3. **Configure INI:** Ensures `extension=timezonedb.so` is present in `/usr/local/phpXX/lib/php.conf.d/10-directadmin.ini`.
4. **Restart FPM:** Restarts `php-fpmXX` via `systemctl`.
5. **Verify:** Executes inline PHP CLI code:
```php
echo 'Time: ' . date('Y-m-d H:i:s T') . PHP_EOL . 
     'Timezone: ' . date_default_timezone_get() . PHP_EOL . 
     'TimezoneDB: ' . timezone_version_get() . PHP_EOL;

```

---

## ⏰ Cronjob Automation (Optional)

To keep your server's PHP timezone database updated automatically, you can add a monthly cron job:

```bash
# Run on the 1st day of every month at 3:00 AM
0 3 1 * * /usr/local/bin/update_timezonedb.sh > /dev/null 2>&1

```

---

## 📄 License

This project is licensed under the MIT License.
