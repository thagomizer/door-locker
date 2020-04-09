require "minitest/autorun"
require "functions_framework/testing"

ENV['TESTING'] = "true"
ENV['FRONTDOOR'] = "front"
ENV['BACKDOOR'] = "back"

StubResponse = Struct.new(:name) {}

class TasksStub
  attr_accessor :task_history, :count

  def initialize
    @task_history = Hash.new{ |h, k| h[k] = [] }
    @count = 0
  end

  def create_task(parent, task)
    @count += 1

    @task_history[parent] << task

    response = StubResponse.new("Test Task/#{@count}")
  end
end

$TASK_STUB = TasksStub.new

class TestMyFunction < Minitest::Test
  include FunctionsFramework::Testing

  def test_function_returns_success
    load_temporary "locker.rb" do
      request = make_post_request "http://example.com:8080/", "door=front"

      response = nil

      _out, err = capture_subprocess_io do
        response = call_http "lock_door", request
      end

      assert_equal 200, response.status
      assert_match /Created task .*\/\d+/, response.body.join.chomp


      task_stub = $TASK_STUB
      parent = task_stub.task_history.keys.first

      assert_equal parent, "thagomizer-home-automation-us-central1-door-locker"


      task = task_stub.task_history[parent].first

      assert_match /back/, task[:http_request][:url]

    end
  end
end
