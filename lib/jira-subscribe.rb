require 'rest-client'
require 'yaml'
require 'json'
require 'logger'

class JiraSubscribe
  CONFIG = YAML.load_file('config/config.yml').freeze
  SUBSCRIBE_DELAY = 5.freeze        # Время между подписками на задачи
  NEW_TASK_DELAY = (30 * 60).freeze # Время ожидания появления новой задачи

  attr_accessor :username, :password, :task, :url, :thread

  def initialize(params)
    @username = params.fetch(:username)
    @task = params.fetch(:task)
    @password = params.fetch(:password)
    @url = "#{CONFIG['site']}/rest/api/2/issue/"
    @resource = RestClient::Resource.new(watchers(task), @username, @password)
    @logger = Logger.new(STDOUT)
  end

  def watch(current_task)
    @resource = RestClient::Resource.new(watchers(current_task), @username, @password)
    @resource.get
  end

  def subscribe(current_task)
    @resource = RestClient::Resource.new(watchers(current_task), @username, @password)
    @resource.post "\"#{@username}\"", content_type: :json
  end

  def watchers(current_task)
    @url + current_task + '/watchers'
  end

  def start
    project, id = @task.split('/').last.split('-')

    @thread ||= Thread.new do
      @logger.info 'Автоподписка активирована!'

      loop do
        current_task = [project, id].join('-')

        begin
          if JSON(watch(current_task).body)['watchers'].none? { |w| w['name'] == @username }
            subscribe(current_task)
            @logger.info "Подписались на #{current_task}"
          else
            @logger.info "На задачу #{current_task} уже подписаны"
          end

          sleep SUBSCRIBE_DELAY
        rescue RestClient::NotFound
          @logger.warn "Задача #{current_task} не найдена, ждем #{NEW_TASK_DELAY} секунд"
          sleep NEW_TASK_DELAY
          id = id.to_i - 1
        end

        id = id.to_i + 1
      end
    end
  end

  def stop
    return true if stopped?

    @thread.exit
    @logger.info 'Автоподписка остановлена!'

    sleep 1
    !!@thread.status || (@thread = nil) || true
  end

  def stopped?
    !defined?(@thread) || @thread.nil?
  end
end
