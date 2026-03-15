#!/bin/bash

bundle install

cd demo-app
bundle install
npm install
bin/rails db:migrate
