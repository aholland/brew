# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Homebrew
      # This cop ensures that platform specific code ends up in `extend/os`, and
      # that `extend/os` doesn't contain incorrect or redundant OS checks.
      class MoveToExtendOS < Base
        NON_EXTEND_OS_MSG = "Move `OS.linux?` and `OS.mac?` calls to `extend/os`."

        def_node_matcher :os_mac?, <<~PATTERN
          (send (const nil? :OS) :mac?)
        PATTERN

        def_node_matcher :os_linux?, <<~PATTERN
          (send (const nil? :OS) :linux?)
        PATTERN

        sig { params(extend_os: String, os_method: String).returns(String) }
        def extend_offense_message(extend_os, os_method)
          "Don't use `OS.#{os_method}?` in `extend/os/#{extend_os}`, it is " \
            "always `#{(extend_os == os_method) ? "true" : "false"}`."
        end
      end
    end
  end
end
