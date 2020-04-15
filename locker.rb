require "functions_framework"
require "google/cloud/tasks"

PROJECT  = "thagomizer-home-automation"
LOCATION = "us-central1"
QUEUE    = "door-locker"

tasks_client = Google::Cloud::Tasks.new
PARENT = tasks_client.queue_path(PROJECT, LOCATION, QUEUE)

## Env Vars
BACKDOOR = ENV["BACKDOOR"]
FRONTDOOR = ENV["FRONTDOOR"]

DELAY_BACK = 600
DELAY_FRONT = 300
##

FunctionsFramework.http("lock_door") do |request|
  task = {http_request: {http_method: "POST"}}

  door = request.params["door"]

  if door == "back" then
    task[:schedule_time] = {seconds: (Time.now() + DELAY_BACK).to_i}
    task[:http_request] = {url: BACKDOOR}
  elsif door == "front" then
    task[:schedule_time] = {seconds: (Time.now() + DELAY_FRONT).to_i}
    task[:http_request] = {url: FRONTDOOR}
  end

  begin
    response = tasks_client.create_task(PARENT, task)
  rescue Exception => e
    FunctionsFramework.logger.error "Exception creating task"
  end

  puts response.class

  FunctionsFramework.logger.info "Created task #{response.name}"
  "Created task #{response.name}"
end
