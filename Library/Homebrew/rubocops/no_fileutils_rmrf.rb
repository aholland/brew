# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Homebrew
      # This cop checks for the use of `FileUtils.rm_f`, `FileUtils.rm_rf`, or `{FileUtils,instance}.rmtree`
      # and recommends the safer versions.
      class NoFileutilsRmrf < Base
        extend AutoCorrector

        MSG = "Use `rm` or `rm_r` instead of `rm_rf`, `rm_f`, or `rmtree`."

        def_node_matcher :any_receiver_rm_r_f?, <<~PATTERN
          (send
            {(const {nil? cbase} :FileUtils) (self)}
            {:rm_rf :rm_f}
            ...)
        PATTERN

        def_node_matcher :no_receiver_rm_r_f?, <<~PATTERN
          (send nil? {:rm_rf :rm_f} ...)
        PATTERN

        def_node_matcher :no_receiver_rmtree?, <<~PATTERN
          (send nil? :rmtree ...)
        PATTERN

        def_node_matcher :any_receiver_rmtree?, <<~PATTERN

        sig { params(node: RuboCop::AST::SendNode).returns(T::Boolean) }
        def neither_rm_rf_nor_rmtree?(node)
          !any_receiver_rm_r_f?(node) && !no_receiver_rm_r_f?(node) &&
            !any_receiver_rmtree?(node) && !no_receiver_rmtree?(node)
        end
      end
    end
  end
end
