# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    # Checks if rubocop disable comments have a clarifying comment preceding them.
    class DisableComment < Base
      MSG = "Add a clarifying comment to the RuboCop disable comment"

      private

      sig { params(comment: Parser::Source::Comment).returns(T::Boolean) }
      def disable_comment?(comment)
        comment.text.start_with? "# rubocop:disable"
      end

      sig { params(line: String).returns(T::Boolean) }
      def comment?(line)
        line.strip.start_with?("#") && line.strip.delete_prefix("#") != ""
      end
    end
  end
end
