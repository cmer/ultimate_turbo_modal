# frozen_string_literal: true

require "rails/generators"
require "pathname"

module UltimateTurboModal
  module Generators
    class Base < Rails::Generators::Base
      protected

      def package_name
        "ultimate_turbo_modal"
      end

      # Add JS dependency (for install flow)
      def add_js_dependency
        say "Attempting to set up JavaScript dependencies...", :yellow

        version_spec = "#{package_name}@#{UltimateTurboModal::VERSION}"

        if uses_importmaps?
          say "Detected Importmaps. Pinning #{version_spec}...", :green
          run "bin/importmap pin #{version_spec}"
          say "✅ Pinned '#{package_name}' via importmap.", :green
          return
        end

        if uses_javascript_bundler?
          say "Detected jsbundling-rails (Yarn/npm/Bun). Adding #{package_name} package...", :green
          if uses_yarn?
            run "yarn add #{version_spec}"
            say "✅ Added '#{package_name}' using Yarn.", :green
          elsif uses_npm?
            run "npm install --save #{version_spec}"
            say "✅ Added '#{package_name}' using npm.", :green
          elsif uses_bun?
            run "bun add #{version_spec}"
            say "✅ Added '#{package_name}' using Bun.", :green
          else
            say "Attempting to add with Yarn. If you use npm or Bun, please add manually.", :yellow
            run "yarn add #{version_spec}"
            say "If this failed or you use npm/bun, please run:", :yellow
            say "npm install --save #{version_spec}", :cyan
            say "# or", :cyan
            say "bun add #{version_spec}", :cyan
          end
        else
          say "Could not automatically detect Importmaps or jsbundling-rails.", :yellow
          say "Please manually add the '#{package_name}' JavaScript package.", :yellow
          say "If using Importmaps: bin/importmap pin #{version_spec}", :cyan
          say "If using Yarn: yarn add #{version_spec}", :cyan
          say "If using npm: npm install --save #{version_spec}", :cyan
          say "If using Bun: bun add #{version_spec}", :cyan
          say "Then, import it in your app/javascript/application.js:", :yellow
          say "import '#{package_name}'", :cyan
        end
      end

      # Install all JS dependencies (for update flow)
      def install_all_js_dependencies
        if uses_importmaps?
          version_spec = "#{package_name}@#{UltimateTurboModal::VERSION}"
          say "Detected Importmaps. Ensuring pin for #{version_spec}...", :green
          run "bin/importmap pin #{version_spec}"
          say "✅ Pinned '#{package_name}' via importmap.", :green
          return
        end

        unless uses_javascript_bundler?
          say "Could not detect Importmaps or jsbundling-rails. Skipping JS install step.", :yellow
          return
        end

        say "Installing JavaScript dependencies...", :yellow
        if uses_yarn?
          run "yarn install"
          say "✅ Installed dependencies with Yarn.", :green
        elsif uses_npm?
          run "npm install"
          say "✅ Installed dependencies with npm.", :green
        elsif uses_bun?
          run "bun install"
          say "✅ Installed dependencies with Bun.", :green
        else
          say "Attempting to install with Yarn. If you use npm or Bun, please run the appropriate command.", :yellow
          run "yarn install"
        end
      end

      def uses_importmaps?
        File.exist?(rails_root_join("config", "importmap.rb"))
      end

      def uses_javascript_bundler?
        File.exist?(rails_root_join("package.json"))
      end

      def uses_yarn?
        File.exist?(rails_root_join("yarn.lock"))
      end

      def uses_npm?
        File.exist?(rails_root_join("package-lock.json")) && !uses_yarn? && !uses_bun?
      end

      def uses_bun?
        File.exist?(rails_root_join("bun.lockb"))
      end

      def rails_root_join(*args)
        Pathname.new(destination_root).join(*args)
      end
    end
  end
end


