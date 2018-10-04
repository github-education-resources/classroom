# frozen_string_literal: true

# Executes an ActiveRecord `#touch` call on all ElasticSearch indexed models.
# Each `#touch` triggers an ElasticSearch reindex with the `:active_job` strategy.
task elasticsearch_reindex: :environment do

  task_stats = {}
  Chewy.strategy(:active_job) do
    ElasticSearch.models.each do |model|
      task_stats[model.to_s] = 0
      model.find_in_batches(batch_size: 100) do |model_instances|
        model_instances.each do |model_instance|
          model_instance.touch
          task_stats[model.to_s] += 1
        end
      end
    end
  end

  puts("=============================")
  puts("------- Reindex Stats -------")
  puts("=> # of models touched")
  print("=> ")
  pp task_stats
  puts("=============================")
end
