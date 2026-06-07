# typed: strong
# frozen_string_literal: true

require "utils/output"

# Used by the {Utils::Inreplace.inreplace} function.
class StringInreplaceExtension
  include Utils::Output::Mixin

  sig { returns(T::Array[String]) }
  attr_accessor :errors

  sig { returns(String) }
  attr_accessor :inreplace_string

  sig { params(string: String).void }
  def initialize(string)
    @inreplace_string = string
    @errors = T.let([], T::Array[String])
  end

  # Same as `String#sub!`, but warns if nothing was replaced.
  #
  # @api public
  sig { params(before: T.any(Regexp, String), after: String, audit_result: T::Boolean).returns(T.nilable(String)) }
  def sub!(before, after, audit_result: true)
    result = inreplace_string.sub!(before, after)
    errors << "expected replacement of #{before.inspect} with #{after.inspect}" if audit_result && result.nil?
    result
  end

  # Same as `String#gsub!`, but warns if nothing was replaced.
  #
  # @api public
  sig {
    params(
      before:       T.any(Pathname, Regexp, String),
      after:        T.any(Pathname, String),
      audit_result: T::Boolean,
    ).returns(T.nilable(String))
  }
  def gsub!(before, after, audit_result: true)
    before = before.to_s if before.is_a?(Pathname)
    result = inreplace_string.gsub!(before, after.to_s)
    errors << "expected replacement of #{before.inspect} with #{after.inspect}" if audit_result && result.nil?
    result
  end
end
