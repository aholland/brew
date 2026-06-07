# typed: strict
# frozen_string_literal: true

require "keg"
require "formula"
require "formulary"
require "utils"
require "version"
require "development_tools"
require "utils/shell"
require "utils/output"
require "cask/caskroom"
require "cask/quarantine"
require "git_repository"
require "missing"
require "system_command"
require "trust"

module Homebrew
  # Module containing diagnostic checks.
  module Diagnostic
    extend Utils::Output::Mixin

    sig { params(type: Symbol, fatal: T::Boolean).void }
    def self.checks(type, fatal: true)
      @checks ||= T.let(Checks.new, T.nilable(Checks))
      failed = T.let(false, T::Boolean)
      @checks.public_send(type).each do |check|
        out = @checks.public_send(check)
        next if out.nil?

        if fatal
          failed ||= true
          ofail out
        else
          opoo out
        end
      end
      exit 1 if failed && fatal
    end

    # Diagnostic checks.
    class Checks
      include SystemCommand::Mixin
      include Utils::Output::Mixin

      sig { params(verbose: T::Boolean).void }
      def initialize(verbose: true)
        @verbose = verbose
        @found = T.let([], T::Array[String])
        @seen_prefix_bin = T.let(false, T::Boolean)
        @seen_prefix_sbin = T.let(false, T::Boolean)
        @user_path_1_done = T.let(false, T::Boolean)
        @non_core_taps = T.let([], T.nilable(T::Array[Tap]))
      end

      ############# @!group HELPERS
      # Finds files in `HOMEBREW_PREFIX` *and* /usr/local.
      # Specify paths relative to a prefix, e.g. "include/foo.h".
      # Sets @found for your convenience.
      sig { params(relative_paths: T.any(String, T::Array[String])).void }
      def find_relative_paths(*relative_paths)
        @found = [HOMEBREW_PREFIX, "/usr/local"].uniq.reduce([]) do |found, prefix|
          found + relative_paths.map { |f| File.join(prefix, f) }.select { |f| File.exist? f }
        end
      end

      sig { params(list: T::Array[T.any(Formula, Pathname, String)], string: String).returns(String) }
      def inject_file_list(list, string)
        list.reduce(string.dup) { |acc, elem| acc << "  #{elem}\n" }
            .freeze
      end

      sig { params(path: String).returns(String) }
      def user_tilde(path)
        home = Dir.home
        if path == home
          "~"
        else
          path.gsub(%r{^#{home}/}, "~/")
        end
      end

      sig { returns(T.nilable(String)) }
      def none_string
        "<NONE>"
      end

      sig { params(args: T.anything).void }
      def add_info(*args)
        ohai(*args) if @verbose
      end
      ############# @!endgroup END HELPERS

      sig { returns(T::Array[String]) }
      def supported_configuration_checks
        [].freeze
      end

      sig { returns(T::Array[String]) }
      def build_from_source_checks
        [].freeze
      end

      sig { returns(T::Array[String]) }
      def build_error_checks
        supported_configuration_checks + build_from_source_checks
      end

      sig { params(tier: T.any(Integer, String, Symbol)).returns(T.nilable(String)) }
      def support_tier_message(tier:)
        return if tier.to_s == "1"

        tier_title, tier_slug, tier_issues = if tier.to_s == "unsupported"
          ["Unsupported", "unsupported", "Do not report any issues"]
        else
          ["Tier #{tier}", "tier-#{tier.to_s.downcase}", "You can report issues with Tier #{tier} configurations"]
        end

        <<~EOS
          This is a #{tier_title} configuration:
            #{Formatter.url("https://docs.brew.sh/Support-Tiers##{tier_slug}")}
          #{Formatter.bold("#{tier_issues} to Homebrew/* repositories!")}
          Read the above document before opening any issues or PRs.
        EOS
      end

      sig { params(repository_path: GitRepository, desired_origin: String).returns(T.nilable(String)) }
      def examine_git_origin(repository_path, desired_origin)
        return if !Utils::Git.available? || !repository_path.git_repository?

        current_origin = repository_path.origin_url

        if current_origin.nil?
          <<~EOS
            Missing #{desired_origin} git origin remote.

            Without a correctly configured origin, Homebrew won't update
            properly. You can solve this by adding the remote:
              git -C "#{repository_path}" remote add origin #{Formatter.url(desired_origin)}
          EOS
        elsif !current_origin.match?(%r{#{desired_origin}(\.git|/)?$}i)
          <<~EOS
            Suspicious #{desired_origin} git origin remote found.
            The current git origin is:
              #{current_origin}

            With a non-standard origin, Homebrew won't update properly.
            You can solve this by setting the origin remote:
              git -C "#{repository_path}" remote set-url origin #{Formatter.url(desired_origin)}
          EOS
        end
      end

      sig { params(tap: Tap).returns(T.nilable(String)) }
      def broken_tap(tap)
        return unless Utils::Git.available?

        repo = GitRepository.new(HOMEBREW_REPOSITORY)
        return unless repo.git_repository?

        message = <<~EOS
          #{tap.full_name} was not tapped properly! Run:
            rm -rf "#{tap.path}"
            brew tap #{tap.name}
        EOS

        return message if tap.remote.blank?

        tap_head = tap.git_head
        return message if tap_head.blank?
        return if tap_head != repo.head_ref

        message
      end

      sig { params(dir: String, pattern: String, allow_list: T::Array[String], message: String).returns(T.nilable(String)) }
      def __check_stray_files(dir, pattern, allow_list, message)
        return unless File.directory?(dir)

        files = Dir.chdir(dir) do
          (Dir.glob(pattern) - Dir.glob(allow_list))
            .select { |f| File.file?(f) && !File.symlink?(f) }
            .map do |f|
              f.sub!(%r{/.*}, "/*") unless @verbose
              File.join(dir, f)
            end
            .sort.uniq
        end
        return if files.empty?

        inject_file_list(files, message)
      end

      sig { returns(T.nilable(String)) }
      def check_user_path_1
        @seen_prefix_bin = false
        @seen_prefix_sbin = false

        message = ""

        paths.each do |p|
          case p
          when "/usr/bin"
            unless @seen_prefix_bin
              # only show the doctor message if there are any conflicts
              # rationale: a default install should not trigger any brew doctor messages
              conflicts = Dir["#{HOMEBREW_PREFIX}/bin/*"]
                          .map { |fn| File.basename fn }
                          .select { |bn| File.exist? "/usr/bin/#{bn}" }

              unless conflicts.empty?
                message = inject_file_list conflicts, <<~EOS
                  /usr/bin occurs before #{HOMEBREW_PREFIX}/bin in your PATH.
                  This means that system-provided programs will be used instead of those
                  provided by Homebrew. Consider setting your PATH so that
                  #{HOMEBREW_PREFIX}/bin occurs before /usr/bin. Here is a one-liner:
                    #{Utils::Shell.prepend_path_in_profile("#{HOMEBREW_PREFIX}/bin")}

                  The following tools exist at both paths:
                EOS
              end
            end
          when "#{HOMEBREW_PREFIX}/bin"
            @seen_prefix_bin = true
          when "#{HOMEBREW_PREFIX}/sbin"
            @seen_prefix_sbin = true
          end
        end

        @user_path_1_done = true
        message unless message.empty?
      end

      sig { returns(T.nilable(String)) }
      def check_for_non_prefixed_coreutils
        coreutils = Formula["coreutils"]
        return unless coreutils.any_version_installed?

        gnubin = %W[#{coreutils.opt_libexec}/gnubin #{coreutils.libexec}/gnubin]
        return unless paths.intersect?(gnubin)

        <<~EOS
          Putting non-prefixed coreutils in your path can cause GMP builds to fail.
        EOS
      rescue FormulaUnavailableError
        nil
      end

      sig { returns(T::Array[Tap]) }
      def non_core_taps
        @non_core_taps ||= Tap.installed.reject(&:core_tap?).reject(&:core_cask_tap?)
      end

      sig { returns(T::Array[String]) }
      def all
        methods.map(&:to_s).grep(/^check_/).sort
      end

      sig { returns(T::Array[String]) }
      def cask_checks
        all.grep(/^check_cask_/)
      end

      sig { returns(String) }
      def current_user
        ENV.fetch("USER", "$(whoami)")
      end

      private

      sig { returns(T::Array[String]) }
      def paths
        @paths ||= T.let(ORIGINAL_PATHS.uniq.map(&:to_s), T.nilable(T::Array[String]))
      end
    end
  end
end

require "extend/os/diagnostic"
