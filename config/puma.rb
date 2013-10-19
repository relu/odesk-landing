#!/usr/bin/env puma

require 'fileutils'

environment 'production'
bind 'unix:///tmp/puma.sock'
threads 8,32
workers 3
preload_app!

on_worker_boot do
  FileUtils.touch('/tmp/app-initialized')
end
