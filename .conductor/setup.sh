#!/bin/bash

if command -v mise &> /dev/null; then
    mise trust
fi

bundle install

cd demo-app
bundle install
npm install
bin/rails db:migrate
