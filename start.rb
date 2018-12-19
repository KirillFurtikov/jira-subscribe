#!/usr/bin/env ruby
require 'irb'
require 'io/console'
require_relative 'lib/jira-subscribe'

print 'Имя пользователя: '
username = gets.chomp

print 'Пароль: '
password = STDIN.noecho(&:gets).chomp

print "\r\nНомер задачи (Например: TASK-1): "
task = gets.chomp

params = {
  username: username,
  password: password,
  task: task
}

@client = JiraSubscribe.new(params)

IRB.start

