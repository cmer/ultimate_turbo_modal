# frozen_string_literal: true

require "rails/generators"
require "json"
require_relative "base"

module UltimateTurboModal
  module Generators
    class UpdateGenerator < UltimateTurboModal::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Updates UltimateTurboModal: aligns npm package version to gem version and refreshes the configured flavor initializer."

      class_option :flavor, type: :string, desc: "CSS framework flavor (e.g. tailwind, vanilla, custom). Skips auto-detection when provided."

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
        new_version = gem_version_to_npm(UltimateTurboModal::VERSION.to_s)

        # Special case: demo app links to local JS package; never update its version
        local_link = json.dig("dependencies", package_name) || json.dig("devDependencies", package_name)
        if local_link&.match?(/\A(file|link):/)
          say "Detected local link for '#{package_name}' (#{local_link}). Skipping version update.", :blue
          return
        end

        found = false
        updated = false

        %w[dependencies devDependencies].each do |section|
          next unless json.key?(section) && json[section].is_a?(Hash)

          if json[section].key?(package_name)
            found = true
            old = json[section][package_name]
            json[section][package_name] = new_version
            updated = true if old != new_version
          end
        end

        if updated
          File.write(package_json_path, JSON.pretty_generate(json) + "\n")
          say "Updated #{package_name} version in package.json to #{new_version}.", :green
        elsif found
          say "#{package_name} in package.json is already at version #{new_version}.", :blue
        else
          json["dependencies"] ||= {}
          json["dependencies"][package_name] = new_version
          File.write(package_json_path, JSON.pretty_generate(json) + "\n")
          say "Added #{package_name} (#{new_version}) to package.json dependencies.", :green
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
        return options[:flavor] if options[:flavor]

        rails_bin = rails_root_join("bin", "rails")
        command = File.exist?(rails_bin) ? rails_bin.to_s : "bundle exec rails"
        output = `#{command} runner "puts UltimateTurboModal.configuration.flavor"`.to_s.strip
        output.empty? ? nil : output
      rescue => e
        say "Error determining flavor via rails runner: #{e.message}", :red
        nil
      end
    end
  end
end
