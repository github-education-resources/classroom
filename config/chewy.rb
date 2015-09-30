Chewy.logger = Rails.logger

ActiveSupport::Notifications.subscribe('import_objects.chewy') do |name, start, finish, id, payload|
  metric_name = "Database/ElasticSearch/import"
  duration = (finish - start).to_f
  logged = "#{payload[:type]} #{payload[:import].to_a.map{ |i| i.join(':') }.join(', ')}"

  self.class.trace_execution_scoped([metric_name]) do
    NewRelic::Agent.instance.transaction_sampler.notice_sql(logged, nil, duration)
    NewRelic::Agent.instance.sql_sampler.notice_sql(logged, metric_name, nil, duration)
    NewRelic::Agent.record_metric(metric_name, duration)
  end
end

ActiveSupport::Notifications.subscribe('search_query.chewy') do |name, start, finish, id, payload|
  metric_name = "Database/ElasticSearch/search"
  duration = (finish - start).to_f
  logged = "#{payload[:type].presence || payload[:index]} #{payload[:request]}"

  self.class.trace_execution_scoped([metric_name]) do
    NewRelic::Agent.instance.transaction_sampler.notice_sql(logged, nil, duration)
    NewRelic::Agent.instance.sql_sampler.notice_sql(logged, metric_name, nil, duration)
    NewRelic::Agent.record_metric(metric_name, duration)
  end
end
