#!/usr/bin/env puma

require 'fileutils'

environment 'production'
bind 'unix:///tmp/puma.sock'

on_worker_boot do
  FileUtils.touch('/tmp/app-initialized')
end
