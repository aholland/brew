# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Homebrew
      # Enforces the use of `Homebrew.install_bundler_gems!` in dev-cmd.
      class InstallBundlerGems < Base
        MSG = "Only use `Homebrew.install_bundler_gems!` in dev-cmd."
      end
    end
  end
end
