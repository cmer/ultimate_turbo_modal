# frozen_string_literal: true

require "rails/generators"
require_relative "base"

module UltimateTurboModal
  module Generators
    class InstallGenerator < UltimateTurboModal::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs UltimateTurboModal: copies initializer/flavor, sets up JS, registers Stimulus controller, adds Turbo Frame."

      class_option :flavor, type: :string, desc: "CSS framework flavor (e.g. tailwind, vanilla, custom)"

      # Step 1: Determine CSS framework flavor
      def determine_framework_flavor
        @framework = options[:flavor] || prompt_for_flavor
        validate_flavor!(@framework)
      end

      # Step 2: Setup Javascript Dependencies (Yarn/npm/Bun or Importmap)
      def setup_javascript_dependencies
        add_js_dependency
      end

      # Step 3: Register Stimulus Controller
      def setup_stimulus_controller
        index_path = rails_root_join("app", "javascript", "controllers", "index.js")
        application_path = rails_root_join("app", "javascript", "controllers", "application.js")
        controller_name = "UltimateTurboModalController"
        stimulus_identifier = "modal"

        import_line = "import { #{controller_name} } from \"#{package_name}\"\n"
        register_line = "application.register(\"#{stimulus_identifier}\", #{controller_name})\n"

        # Determine which file contains Application.start() — it may be index.js or application.js
        target_path, file_content = find_stimulus_target(index_path, application_path)

        say "\nAttempting to register Stimulus controller...", :yellow

        unless target_path
          say "❌ Stimulus controllers file not found.", :red
          say "   Please manually add the following lines to your Stimulus setup:", :yellow
          say "   #{import_line.strip}", :cyan
          say "   #{register_line.strip}\n", :cyan
          return
        end

        say "  Target file: #{target_path}", :yellow

        # Insert the import statement after an existing import from @hotwired/stimulus or ./application
        import_anchor = /import .* from ["'](?:@hotwired\/stimulus|\.\/application)["']\n/
        if file_content.include?(import_line)
          say "⏩ Import statement already exists.", :blue
        elsif file_content.match?(import_anchor)
          insert_into_file target_path, import_line, after: import_anchor
          say "✅ Added import statement.", :green
        elsif file_content.match?(/import/)
          insert_into_file target_path, import_line, before: /import/
          say "✅ Added import statement (fallback position).", :green
        else
          prepend_to_file target_path, import_line
          say "✅ Added import statement (prepended to file).", :green
        end

        # Insert the register statement after Application.start()
        register_anchor = /Application\.start\(\)\n/
        if file_content.include?(register_line)
          say "⏩ Controller registration already exists.", :blue
        elsif file_content.match?(register_anchor)
          insert_into_file target_path, register_line, after: register_anchor
          say "✅ Added controller registration.", :green
        else
          say "❌ Could not find `Application.start()` line in #{target_path}.", :red
          say "   Please manually add these lines to your Stimulus setup:", :yellow
          say "   #{import_line.strip}", :cyan
          say "   #{register_line.strip}\n", :cyan
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

      def available_flavors
        flavors_dir = File.expand_path("templates/flavors", __dir__)
        flavors = Dir.glob(File.join(flavors_dir, "*.rb")).map { |file| File.basename(file, ".rb") }.sort
        if flavors.include?("custom")
          flavors.delete("custom")
          flavors << "custom"
        end
        flavors
      end

      def validate_flavor!(flavor)
        flavors = available_flavors
        if flavors.empty?
          raise Thor::Error, "No flavor templates found!"
        end
        unless flavors.include?(flavor)
          raise Thor::Error, "Invalid flavor '#{flavor}'. Available flavors: #{flavors.join(", ")}"
        end
      end

      def prompt_for_flavor
        flavors = available_flavors

        if flavors.empty?
          raise Thor::Error, "No flavor templates found!"
        end

        say "Which CSS framework does your project use?\n", :blue
        say "Options:"
        flavors.each_with_index do |option, index|
          say "#{index + 1}. #{option}"
        end

        loop do
          print "\nEnter the number: "
          framework_choice = ask("").chomp.strip
          framework_id = framework_choice.to_i - 1

          if framework_id >= 0 && framework_id < flavors.size
            return flavors[framework_id]
          else
            say "\nInvalid option '#{framework_choice}'. Please enter a number between 1 and #{flavors.size}.", :red
          end
        end
      end

      def find_stimulus_target(index_path, application_path)
        [index_path, application_path].each do |path|
          next unless File.exist?(path)
          content = File.read(path)
          return [path, content] if content.match?(/Application\.start\(\)/)
        end

        # Fall back to index.js even without Application.start()
        if File.exist?(index_path)
          [index_path, File.read(index_path)]
        end
      end
    end
  end
end
