# frozen_string_literal: true

namespace :utmr do
  desc "Show the configured UltimateTurboModal flavor"
  task flavor: :environment do
    puts UltimateTurboModal.configuration.flavor
  end
end
