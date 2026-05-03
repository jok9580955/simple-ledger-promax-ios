#!/usr/bin/env ruby

require "spaceship"

app_identifier = ENV.fetch("APP_IDENTIFIER", "com.daniao.simpleledgerpromax")
key_id = ENV.fetch("APP_STORE_CONNECT_API_KEY_ID", "JD5G4LG5XN")
issuer_id = ENV.fetch("APP_STORE_CONNECT_API_KEY_ISSUER_ID", "f68594d0-23a9-480d-8f1d-6c84b40bf664")
key_filepath = File.expand_path(ENV.fetch("APP_STORE_CONNECT_API_KEY_KEYFILEPATH", "/Users/ll/Desktop/AuthKey_JD5G4LG5XN.p8"))
screenshots_path = File.expand_path(ENV.fetch("SCREENSHOTS_PATH", File.join(__dir__, "..", "fastlane", "screenshots")))

unless File.exist?(key_filepath)
  abort("Missing App Store Connect API key file: #{key_filepath}")
end

Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: key_id,
  issuer_id: issuer_id,
  filepath: key_filepath,
  duration: 1200,
  in_house: false
)

app = Spaceship::ConnectAPI::App.find(app_identifier)
abort("App not found for #{app_identifier}") unless app

version = app.get_edit_app_store_version
abort("Editable App Store version not found for #{app_identifier}") unless version

locales = Dir.children(screenshots_path).select do |entry|
  File.directory?(File.join(screenshots_path, entry))
end.sort

missing = []
incomplete = []
total_sets = 0
total_screenshots = 0

puts "App: #{app_identifier}"
puts "Version: #{version.version_string}"
puts "Locale count: #{locales.length}"

localizations = version.get_app_store_version_localizations(includes: nil, limit: 200)
localization_by_locale = localizations.each_with_object({}) do |localization, result|
  result[localization.locale] = localization
end

locales.each do |locale|
  localization = localization_by_locale[locale]
  if localization.nil?
    missing << "#{locale}: missing localization"
    puts "#{locale}: missing localization"
    next
  end

  sets = localization.get_app_screenshot_sets(includes: "appScreenshots", limit: 50)
  states = {}
  counts = sets.each_with_object({}) do |set, result|
    screenshots = Array(set.app_screenshots)
    result[set.screenshot_display_type] = screenshots.length
    states[set.screenshot_display_type] = screenshots.each_with_object(Hash.new(0)) do |screenshot, state_counts|
      state = screenshot.asset_delivery_state&.fetch("state", nil) || "UNKNOWN"
      state_counts[state] += 1
      incomplete << "#{locale} #{set.screenshot_display_type} #{screenshot.file_name}: #{state}" unless state == "COMPLETE"
    end
  end

  total_sets += counts.length
  total_screenshots += counts.values.sum
  summary = counts.sort.map do |display_type, count|
    state_summary = states.fetch(display_type, {}).sort.map { |state, state_count| "#{state}:#{state_count}" }.join("/")
    "#{display_type}=#{count}(#{state_summary})"
  end.join(", ")
  puts "#{locale}: #{summary}"

  locale_total = counts.values.sum
  missing << "#{locale}: expected 10 screenshots, found #{locale_total}" unless locale_total == 10
end

puts "Total screenshot sets: #{total_sets}"
puts "Total screenshots: #{total_screenshots}"

if missing.empty? && incomplete.empty? && total_screenshots == locales.length * 10
  puts "OK: all expected screenshots are present."
else
  warn "Missing/incomplete/not complete:"
  missing.each { |item| warn "- #{item}" }
  incomplete.each { |item| warn "- #{item}" }
  exit 1
end
