# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

#Sam: (517) 610-4488

SATELLITE_LOCATIONS = {
  'hillsdale' => '192.168.10.21:5050',
  'coldwater' => '192.168.11.21:5050',
  'angola' => '192.168.12.21:5050',
  'jonesville' => '192.168.13.21:5050',
  'jackson' => '192.168.14.21:5050',
  'hudson' => '192.168.15.21:5050',
  'middlebelt' => 'malibu-middlebelt.no-ip.com:5050',
  'fortwayne' => '192.168.17.21:5050'
}
