require_relative 'app/base/server/store'
require_relative 'app/models/entry'
require_relative 'app/models/time_box'
require_relative 'app/scheduler'

scheduler = ForgetMeNot::Scheduler.new

p TimePeriod.now
scheduler.reschedule(TimePeriod.now)
