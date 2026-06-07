# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Homebrew
      # This cop restricts usage of `IO.read` functions for security reasons.
      class IORead < Base
        MSG = "The use of `IO.%<method>s` is a security risk."

        private

        sig { params(node: RuboCop::AST::Node).returns(T::Boolean) }
        def safe?(node)
          if node.str_type?
            !node.str_content.empty? && !node.str_content.start_with?("|")
          elsif node.dstr_type? || (node.send_type? && T.cast(node, RuboCop::AST::SendNode).method?(:+))
            safe?(node.children.first)
          else
            false
          end
        end
      end
    end
  end
end
