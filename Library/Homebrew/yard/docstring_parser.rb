# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../extend/module"

# from https://github.com/lsegal/yard/issues/484#issuecomment-442586899
module Homebrew
  module YARD
    class DocstringParser < ::YARD::DocstringParser
      # Every `Object` has these methods.
      unless const_defined?(:OVERRIDABLE_METHODS, false)
        OVERRIDABLE_METHODS = [
          :hash, :inspect, :to_s,
          :<=>, :===, :!~, :eql?, :equal?, :!, :==, :!=
        ].freeze
        private_constant :OVERRIDABLE_METHODS
      end
      unless const_defined?(:SELF_EXPLANATORY_METHODS, false)
        SELF_EXPLANATORY_METHODS = [:to_yaml, :to_json, :to_str].freeze
        private_constant :SELF_EXPLANATORY_METHODS
      end
    end
  end
end

YARD::Docstring.default_parser = Homebrew::YARD::DocstringParser
