require 'functions_framework'
require 'google/cloud/tasks'


PROJECT  = 'thagomizer-home-automation'
LOCATION = 'us-central1'
QUEUE    = 'door-locker'

if ENV['TESTING']
  tasks_client = $TASK_STUB
  PARENT = "#{PROJECT}-#{LOCATION}-#{QUEUE}"
else
  tasks_client = Google::Cloud::Tasks.new
  PARENT = Google::Cloud::Tasks::V2::CloudTasksClient.queue_path(PROJECT, LOCATION, QUEUE)
end

## Env Vars
BACKDOOR = ENV['BACKDOOR']
FRONTDOOR = ENV['FRONTDOOR']

DELAY_BACK = 600
DELAY_FRONT = 300
##

FunctionsFramework.http("lock_door") do |request|
  task = {http_request: {http_method: 'POST'}}

  door = request.params["door"] || "front"

  if door == "back" then
    task[:schedule_time] = {seconds: (Time.now() + DELAY_BACK).to_i}
    task[:http_request] = {url: BACKDOOR}
  elsif door == "front" then
    task[:schedule_time] = {seconds: (Time.now() + DELAY_FRONT).to_i}
    task[:http_request] = {url: FRONTDOOR}
  end

  response = nil

  begin
    response = tasks_client.create_task(PARENT, task)
  rescue Exception => e
    FunctionsFramework.logger.error "Exception creating task"
  end

  FunctionsFramework.logger.info "Created task #{response.name}"
  "Created task #{response.name}"
end
