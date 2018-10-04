# frozen_string_literal: true

# Executes an `update_index` call on all ElasticSearch indexed models.
task elasticsearch_reindex: :environment do
  task_stats = {}
  Chewy.strategy(:active_job) do
    ESIndices.models.each do |model|
      model_name = model.to_s.underscore
      task_stats[model.to_s] = 0
      model.find_in_batches(batch_size: 100) do |model_instances|
        model_instances.each do |model_instance|
          model.update_index("#{model_name}##{model_name}") { model_instance }
          task_stats[model.to_s] += 1
        end
      end
    end
  end

  puts("=======================================")
  puts("------------ Reindex Stats ------------")
  puts("Number of reindexing jobs triggered:")
  print("=> ")
  pp task_stats
  puts("=======================================")
end
