# frozen_string_literal: true

require "rails/generators"
require "pathname" # Needed for Pathname helper
require_relative "base"

module UltimateTurboModal
  module Generators
    class InstallGenerator < UltimateTurboModal::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs UltimateTurboModal: copies initializer/flavor, sets up JS, registers Stimulus controller, adds Turbo Frame."

      # Step 1: Determine CSS framework flavor
      def determine_framework_flavor
        @framework = prompt_for_flavor
      end

      # Step 2: Setup Javascript Dependencies (Yarn/npm/Bun or Importmap)
      def setup_javascript_dependencies
        add_js_dependency
      end

      # Step 3: Register Stimulus Controller
      def setup_stimulus_controller
        stimulus_controller_path = rails_root_join("app", "javascript", "controllers", "index.js")
        controller_package = "ultimate_turbo_modal" # Package name where the controller is defined
        controller_name = "UltimateTurboModalController" # The exported controller class name
        stimulus_identifier = "modal" # The identifier for application.register

        import_line = "import { #{controller_name} } from \"#{controller_package}\"\n"
        register_line = "application.register(\"#{stimulus_identifier}\", #{controller_name})\n"

        say "\nAttempting to register Stimulus controller in #{stimulus_controller_path}...", :yellow

        unless File.exist?(stimulus_controller_path)
          say "❌ Stimulus controllers index file not found at #{stimulus_controller_path}.", :red
          say "   Please manually add the following lines to your Stimulus setup:", :yellow
          say "   #{import_line.strip}", :cyan
          say "   #{register_line.strip}\n", :cyan
          return # Exit this method if the file doesn't exist
        end

        # Read the file content to check if lines already exist
        file_content = File.read(stimulus_controller_path)

        # Insert the import statement after the last existing import or a common marker
        # Using a regex to find the Stimulus import is often reliable
        import_anchor = /import .* from "@hotwired\/stimulus"\n/
        if file_content.match?(import_anchor) && !file_content.include?(import_line)
          insert_into_file stimulus_controller_path, import_line, after: import_anchor
          say "✅ Added import statement.", :green
        elsif !file_content.include?(import_line)
          # Fallback: insert at the beginning if Stimulus import wasn't found (less ideal)
          insert_into_file stimulus_controller_path, import_line, before: /import/
          say "✅ Added import statement (fallback position).", :green
        else
           say "⏩ Import statement already exists.", :blue
        end


        # Insert the register statement after Application.start()
        register_anchor = /Application\.start$$$$\n/
        if file_content.match?(register_anchor) && !file_content.include?(register_line)
           insert_into_file stimulus_controller_path, register_line, after: register_anchor
           say "✅ Added controller registration.", :green
        elsif !file_content.include?(register_line)
          say "❌ Could not find `Application.start()` line to insert registration after.", :red
          say "   Please manually add this line after your Stimulus application starts:", :yellow
          say "   #{register_line.strip}\n", :cyan
        else
           say "⏩ Controller registration already exists.", :blue
        end
      end

      # Step 4: Add Turbo Frame to Layout
      def add_modal_turbo_frame
        layout_path = rails_root_join("app", "views", "layouts", "application.html.erb")
        frame_tag = "<%= turbo_frame_tag \"modal\" %>\n"
        body_tag_regex = /<body.*>\s*\n?/

        say "\nAttempting to add modal Turbo Frame to #{layout_path}...", :yellow

        unless File.exist?(layout_path)
          say "❌ Layout file not found at #{layout_path}.", :red
          say "   Please manually add the following line inside the <body> tag of your main layout:", :yellow
          say "   #{frame_tag.strip}\n", :cyan
          return
        end

        file_content = File.read(layout_path)

        if file_content.include?(frame_tag.strip)
          say "⏩ Turbo Frame tag already exists.", :blue
        elsif file_content.match?(body_tag_regex)
          # Insert after the opening body tag
          insert_into_file layout_path, "  #{frame_tag}", after: body_tag_regex # Add indentation
          say "✅ Added Turbo Frame tag inside the <body>.", :green
        else
          say "❌ Could not find the opening <body> tag in #{layout_path}.", :red
          say "   Please manually add the following line inside the <body> tag:", :yellow
          say "   #{frame_tag.strip}\n", :cyan
        end
      end


      def copy_initializer_and_flavor
        say "\nCreating initializer for `#{@framework}` flavor...", :green
        copy_file "ultimate_turbo_modal.rb", "config/initializers/ultimate_turbo_modal.rb"
        gsub_file "config/initializers/ultimate_turbo_modal.rb", "FLAVOR", ":#{@framework}"
        say "✅ Initializer created at config/initializers/ultimate_turbo_modal.rb"

        say "Copying flavor file...", :green
        copy_file "flavors/#{@framework}.rb", "config/initializers/ultimate_turbo_modal_#{@framework}.rb"
        say "✅ Flavor file copied to config/initializers/ultimate_turbo_modal_#{@framework}.rb\n"
      end

      def show_readme
        say "\nUltimateTurboModal installation complete!\n", :magenta
        say "Please review the initializer files, ensure JS is set up, and check your layout file.", :magenta
        say "Don't forget to restart your Rails server!", :yellow
      end

      private

      def prompt_for_flavor
        say "Which CSS framework does your project use?\n", :blue
        options = []
        flavors_dir = File.expand_path("templates/flavors", __dir__)

        options = Dir.glob(File.join(flavors_dir, "*.rb")).map { |file| File.basename(file, ".rb") }.sort
        if options.include?("custom")
          options.delete("custom")
          options << "custom"
        end

        if options.empty?
           raise Thor::Error, "No flavor templates found in #{flavors_dir}!"
        end

        say "Options:"
        options.each_with_index do |option, index|
          say "#{index + 1}. #{option}"
        end

        loop do
          print "\nEnter the number: "
          framework_choice = ask("").chomp.strip
          framework_id = framework_choice.to_i - 1

          if framework_id >= 0 && framework_id < options.size
            return options[framework_id]
          else
            say "\nInvalid option '#{framework_choice}'. Please enter a number between 1 and #{options.size}.", :red
          end
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
