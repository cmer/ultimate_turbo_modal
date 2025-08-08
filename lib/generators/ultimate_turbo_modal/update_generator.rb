# frozen_string_literal: true

require "rails/generators"
require "json"
require "pathname"
require_relative "base"

module UltimateTurboModal
  module Generators
    class UpdateGenerator < UltimateTurboModal::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Updates UltimateTurboModal: aligns npm package version to gem version and refreshes the configured flavor initializer."

      def update_npm_package_version
        package_json_path = rails_root_join("package.json")

        unless File.exist?(package_json_path)
          say "No package.json found. Skipping npm package version update.", :yellow
          return
        end

        begin
          json = JSON.parse(File.read(package_json_path))
        rescue JSON::ParserError => e
          say "Unable to parse package.json: #{e.message}", :red
          return
        end

        package_name = "ultimate_turbo_modal"
        new_version = UltimateTurboModal::VERSION.to_s

        # Special case: demo app links to local JS package; never update its version
        if json.dig("dependencies", package_name) == "link:../javascript" ||
           json.dig("devDependencies", package_name) == "link:../javascript"
          say "Detected local link for '#{package_name}' (link:../javascript). Skipping version update.", :blue
          return
        end

        updated = false

        %w[dependencies devDependencies].each do |section|
          next unless json.key?(section) && json[section].is_a?(Hash)

          if json[section].key?(package_name)
            old = json[section][package_name]
            json[section][package_name] = new_version
            updated = true if old != new_version
          end
        end

        if updated
          File.write(package_json_path, JSON.pretty_generate(json) + "\n")
          say "Updated #{package_name} version in package.json to #{new_version}.", :green
        else
          say "Did not find #{package_name} in package.json dependencies. Nothing to update.", :blue
        end
      end

      def install_js_dependencies
        install_all_js_dependencies
      end

      def copy_flavor_file
        flavor = detect_flavor
        unless flavor
          say "Could not determine UTMR flavor. Skipping flavor file copy.", :yellow
          return
        end

        template_rel = "flavors/#{flavor}.rb"
        template_abs = File.join(self.class.source_root, template_rel)

        unless File.exist?(template_abs)
          say "Flavor template not found for '#{flavor}' at #{template_abs}.", :red
          return
        end

        target_path = "config/initializers/ultimate_turbo_modal_#{flavor}.rb"
        copy_file template_rel, target_path, force: true
        say "Copied flavor initializer to #{target_path}.", :green
      end

      private

      def detect_flavor
        command = nil
        if File.exist?(rails_root_join("bin", "rails"))
          command = "#{rails_root_join("bin", "rails")} runner \"puts UltimateTurboModal.configuration.flavor\""
        else
          command = "bundle exec rails runner \"puts UltimateTurboModal.configuration.flavor\""
        end

        output = `#{command}`
        flavor = output.to_s.strip
        flavor.empty? ? nil : flavor
      rescue StandardError => e
        say "Error determining flavor via rails runner: #{e.message}", :red
        nil
      end

      def rails_root_join(*args)
        Pathname.new(destination_root).join(*args)
      end
    end
  end
end


