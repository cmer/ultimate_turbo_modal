#!/bin/bash

bundle install

cd demo-app
bundle install
npm install

rails generate ultimate_turbo_modal:update --flavor=tailwind --force
rails generate ultimate_turbo_modal:update --flavor=vanilla --force
bin/rails db:migrate
