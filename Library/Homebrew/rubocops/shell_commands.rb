# typed: strict
# frozen_string_literal: true

require "extend/array"
require "rubocops/shared/helper_functions"
require "shellwords"

module RuboCop
  module Cop
    module Homebrew
      # https://github.com/ruby/ruby/blob/v2_6_3/process.c#L2430-L2460
      SHELL_BUILTINS = %w[
        !
        .
        :
        break
        case
        continue
        do
        done
        elif
        else
        esac
        eval
        exec
        exit
        export
        fi
        for
        if
        in
        readonly
        return
        set
        shift
        then
        times
        trap
        unset
        until
        while
      ].freeze
      private_constant :SHELL_BUILTINS

      # https://github.com/ruby/ruby/blob/v2_6_3/process.c#L2495
      SHELL_METACHARACTERS = %W[* ? { } [ ] < > ( ) ~ & | \\ $ ; ' ` " \n #].freeze
      private_constant :SHELL_METACHARACTERS

      # This cop makes sure that shell command arguments are separated.
      class ShellCommands < Base
        include HelperFunctions
        extend AutoCorrector

        MSG = "Separate `%<method>s` commands into `%<good_args>s`"

        TARGET_METHODS = [
          [nil, :system],
          [nil, :safe_system],
          [nil, :quiet_system],
          [:Utils, :popen_read],
          [:Utils, :safe_popen_read],
          [:Utils, :popen_write],
          [:Utils, :safe_popen_write],
        ].freeze
        private_constant :TARGET_METHODS
      end

      # This cop disallows shell metacharacters in `exec` calls.
      class ExecShellMetacharacters < Base
        include HelperFunctions

        MSG = "Don't use shell metacharacters in `exec`. " \
              "Implement the logic in Ruby instead, using methods like `$stdout.reopen`."
      end
    end
  end
end
