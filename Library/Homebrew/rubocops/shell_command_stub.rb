# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Homebrew
      class ShellCommandStub < Base
        MSG = "Shell command stubs must have a `.sh` counterpart."
      end
    end
  end
end
