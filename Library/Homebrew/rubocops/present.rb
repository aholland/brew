# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Homebrew
      # Checks for code that can be simplified using `Object#present?`.
      #
      # ### Example
      #
      # ```ruby
      # # bad
      # !foo.nil? && !foo.empty?
      #
      # # bad
      # foo != nil && !foo.empty?
      #
      # # good
      # foo.present?
      # ```
      class Present < Base
        extend AutoCorrector

        MSG = "Use `%<prefer>s` instead of `%<current>s`."

        def_node_matcher :exists_and_not_empty?, <<~PATTERN

        sig { params(corrector: RuboCop::Cop::Corrector, node: RuboCop::AST::Node).void }
        def autocorrect(corrector, node)
          variable1, _variable2 = exists_and_not_empty?(node)
          range = node.source_range
          corrector.replace(range, replacement(variable1))
        end

        private

        sig { params(node: T.nilable(RuboCop::AST::Node)).returns(String) }
        def replacement(node)
          node.respond_to?(:source) ? "#{node&.source}.present?" : "present?"
        end
      end
    end
  end
end
