# frozen_string_literal: true

HealthBit.configure do |c|
  # DEFAULT SETTINGS ARE SHOWN BELOW
  c.success_text = '%<count>d checks passed 🎉'
  c.headers = {
    'Content-Type' => 'text/plain;charset=utf-8',
    'Cache-Control' => 'private,max-age=0,must-revalidate,no-store'
  }
  c.success_code = 200
  c.fail_code = 500
  c.show_backtrace = false

  c.add('Check name') do
    # Body check, should returns `true`
    true
  end
end

# Database check
HealthBit.add('Database') do
  ApplicationRecord.connection.select_value('SELECT 1') == 1
end

# Redis check
HealthBit.add('Redis') do
  Redis.current.ping == 'PONG'
end

# Sidekiq check
HealthBit.add('Sidekiq') do
  Sidekiq.redis(&:ping) == 'PONG'
end
