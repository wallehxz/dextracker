class CrontabsController < ApplicationController

  def hour_snapshot
    Exchange.all.map &:hour_snapshot
    render { code: 200, msg: '交易所小时资产同步完成'}
  end

  def day_snapshot
    Exchange.all.map &:day_snapshot
    render { code: 200, msg: '交易所每日资产同步完成'}
  end
end
