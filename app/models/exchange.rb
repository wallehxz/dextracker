# == Schema Information
#
# Table name: exchanges
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  app_key    :string
#  app_secret :string
#  type       :string
#  remark     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Exchange < ActiveRecord::Base
  validates_presence_of :remark, :app_key, :app_secret, :type
  validates_uniqueness_of :app_key, scope: :app_secret
  self.per_page = 10
  has_many :snapshots, dependent: :destroy

  def self.exchanges
    ['binance', 'ftx', 'huo']
  end

  def day_snapshot
    self.snapshots.create(period: 'day', time_stamp: Date.current, estimate: estimate_usdt)
  end

  def hour_snapshot
    self.snapshots.create(period: 'hour', time_stamp: Time.now.at_beginning_of_hour, estimate: estimate_usdt)
  end

  def mock_day_snapshot(days, base_cash)
    current = Date.current
    days.times do |i|
      self.snapshots.create(period: 'day', time_stamp: current, estimate: base_cash + rand(base_cash))
      current -= 1.day
    end
  end

  def mock_hour_snapshot(days, base_cash)
    current = Time.now
    days.times do |i|
      self.snapshots.create(period: 'hour', time_stamp: current.at_beginning_of_hour, estimate: base_cash + rand(base_cash))
      current -= 1.hour
    end
  end

  def self.sync_hour_snapshot
    Exchange.all.map {|e| e.hour_snapshot rescue nil}
  end

  def self.sync_day_snapshot
    Exchange.all.map {|e| e.day_snapshot rescue nil}
  end

  def two_weeks_diff_chart
    "two_weeks_diff_user#{self.id}"
  end

  def day_change_chart
    "day_change_chart#{self.id}"
  end

  def two_weeks_diff_data
    weeks = snapshots.days.order(:time_stamp).last(14)
    time = weeks[7..-1].map {|d| d.time_stamp.to_date.strftime("%A")}
    last_week =  weeks[0..6].map {|d| d.estimate }
    this_week =  weeks[7..-1].map {|d| d.estimate }
    {time: time, last_week: last_week, this_week: this_week}
  end

  def day_change_data
    days = snapshots.hours.order(:time_stamp).last(24)
    time = days.map { |h| h.time_stamp.to_time.strftime("%H:%M") }
    data = days.map {|d| d.estimate }
    {time: time, data: data }
  end

end
