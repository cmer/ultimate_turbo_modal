# frozen_string_literal: true

require_relative "lib/ultimate_turbo_modal/version"

Gem::Specification.new do |spec|
  spec.name = "ultimate_turbo_modal"
  spec.version = UltimateTurboModal::VERSION
  spec.authors = ["Carl Mercier"]
  spec.email = ["foss@carlmercier.com"]

  spec.summary = "UTMR aims to be the be-all and end-all of Turbo Modals."
  spec.description = "An easy-to-use, flexible, and powerful Turbo Modal solution for Rails 8+ built with Stimulus.js, Tailwind CSS (or vanilla CSS) and Hotwire."
  spec.homepage = "https://github.com/cmer/ultimate_turbo_modal"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cmer/ultimate_turbo_modal"
  spec.metadata["changelog_uri"] = "https://github.com/cmer/ultimate_turbo_modal/CHANGELOG.md"

  excluded_dirs = %w[.circleci .claude .conductor .git LLM appveyor bin demo-app docs features javascript screenshots script spec test]
  excluded_files = %w[CLAUDE.md conductor.json ]

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*excluded_dirs) ||
        excluded_files.include?(f)
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "phlex-rails", ">= 2.0"
  spec.add_dependency "actionpack", ">= 8.0"
  spec.add_dependency "activesupport", ">= 8.0"
  spec.add_dependency "railties", ">= 8.0"
  spec.add_dependency "stimulus-rails"
  spec.add_dependency "tsort"
  spec.add_dependency "turbo-rails"
end
