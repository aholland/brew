# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Cask
      class ArrayAlphabetization < Base
        extend AutoCorrector

        sig { params(source: T::Array[String]).returns(T::Array[String]) }
        def sort_array(source)
          # Combine each comment with the line(s) below so that they remain in the same relative location
          combined_source = source.each_with_index.filter_map do |line, index|
            next if line.blank?
            next if line.strip.start_with?("#")

            next recursively_find_comments(source, index, line)
          end

          # Separate the lines into those that should be sorted and those that should not
          # i.e. skip the opening and closing brackets of the array.
          to_sort, to_keep = combined_source.partition { |line| !line.include?("[") && !line.include?("]") }

          # Sort the lines that should be sorted
          to_sort.sort! do |a, b|
            a_non_comment = a.split("\n").reject { |line| line.strip.start_with?("#") }.fetch(0)
            b_non_comment = b.split("\n").reject { |line| line.strip.start_with?("#") }.fetch(0)
            a_non_comment.downcase <=> b_non_comment.downcase || raise("Expected non-comment lines to be present")
          end

          # Merge the sorted lines and the unsorted lines, preserving the original positions of the unsorted lines
          combined_source.map do |line|
            next line if to_keep.include?(line)

            to_sort.shift || raise("Expected to_sort to be present")
          end
        end

        sig { params(source: T::Array[String], index: Integer, line: String).returns(String) }
        def recursively_find_comments(source, index, line)
          if source.fetch(index - 1).strip.start_with?("#")
            return recursively_find_comments(source, index - 1, "#{source[index - 1]}\n#{line}")
          end

          line
        end
      end
    end
  end
end
