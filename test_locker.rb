require "minitest/autorun"
require "functions_framework/testing"
require "minitest/mock"
require "google/cloud/tasks"

ENV["BACKDOOR"] = "back"
ENV["FRONTDOOR"] = "front"

Minitest.autorun

Response = Struct.new(:name) { }

class TasksClientStub
  attr_accessor :task_history, :project, :location, :queue

  def initialize
    @task_history = Hash.new { |h, k| h[k] = [] }
  end

  def create_task parent, task
    @task_history[parent] << task

    Response.new("/#{task_history.length}")
  end

  def queue_path project, location, queue
    @project = project
    @location = location
    @queue = queue

    "projects/#{project}/locations/#{location}/queues/#{queue}"
  end
end

class TestLocker < Minitest::Test
  include FunctionsFramework::Testing

  def test_function_returns_success
    task_stub = TasksClientStub.new

    Google::Cloud::Tasks.stub :new, task_stub do

      load_temporary "locker.rb" do
        request = make_post_request "http://example.com:8080/", "door=front"

        response = nil

        _out, err = capture_subprocess_io do
          response = call_http "lock_door", request
        end

        assert_equal 200, response.status
        assert_match /Created task .*\/\d+/, response.body.join.chomp
      end
    end
  end

  def test_function_creates_correct_task_for_front_door
    task_stub = TasksClientStub.new

    Google::Cloud::Tasks.stub :new, task_stub do

      load_temporary "locker.rb" do
        request = make_post_request "http://example.com:8080/", "door=front"

        response = nil

        _out, err = capture_subprocess_io do
          response = call_http "lock_door", request
        end

        assert_equal 200, response.status


        parent = task_stub.task_history.keys.first
        assert_equal "projects/thagomizer-home-automation/locations/us-central1/queues/door-locker", parent

        task = task_stub.task_history[parent].first

        assert_match /front/, task[:http_request][:url]
      end
    end
  end

  def test_function_creates_correct_task_for_back_door
    task_stub = TasksClientStub.new

    Google::Cloud::Tasks.stub :new, task_stub do

      load_temporary "locker.rb" do
        request = make_post_request "http://example.com:8080/", "door=back"

        response = nil

        _out, err = capture_subprocess_io do
          response = call_http "lock_door", request
        end

        assert_equal 200, response.status


        parent = task_stub.task_history.keys.first
        assert_equal "projects/thagomizer-home-automation/locations/us-central1/queues/door-locker", parent

        task = task_stub.task_history[parent].first

        assert_match /back/, task[:http_request][:url]
      end
    end
  end

end
