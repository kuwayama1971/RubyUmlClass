# frozen_string_literal: true

require_relative "lib/ruby_uml_class/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_uml_class"
  spec.version = RubyUmlClassVer::VERSION
  spec.authors = ["Masataka kuwayama"]
  spec.email = ["masataka.kuwayama@gmail.com"]

  spec.summary = "Create a Ruby UML class diagram."
  spec.description = "Create a Ruby UML class diagram with PlangUml."
  spec.homepage = "https://rubygems.org/gems/browser_app_base"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_development_dependency "browser_app_base"
  spec.add_development_dependency "rufo"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
