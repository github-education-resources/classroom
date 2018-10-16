# frozen_string_literal: true

require "json"

desc "Run a GraphQL Query against the classroom API"
task query: :environment do
  ARGV.each { |a| task a.to_sym }

  QUERY = ARGV[1]
  variables = if ARGV[2]
                eval(ARGV[2]) # rubocop:disable Security/Eval
              else
                {}
              end

  current_user = User.first

  parse_t1 = Time.zone.now
  PARSED_QUERY = GitHubClassroom::ClassroomClient.parse(QUERY)
  parse_t2 = Time.zone.now
  parse_delta = parse_t2 - parse_t1

  query_t1 = Time.zone.now
  response = GitHubClassroom::ClassroomClient.query(PARSED_QUERY,
    variables: variables,
    context: { current_user: current_user })
  query_t2 = Time.zone.now
  query_delta = query_t2 - query_t1

  puts "Response:"
  puts JSON.pretty_generate(response.data.to_h)

  puts

  puts "Parse time: #{parse_delta}"
  puts "Query time: #{query_delta}"
end
