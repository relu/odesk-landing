#!/usr/bin/env puma

environment 'production'
bind 'unix:///tmp/puma.sock'
