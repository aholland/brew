# typed: true
# frozen_string_literal: true

require "cmd/shared_examples/args_parse"
require "dev-cmd/typecheck"

RSpec.describe Homebrew::DevCmd::Typecheck do
  it_behaves_like "parseable arguments"

  describe "#trim_rubocop_rbi" do
    let(:rbi_file) { Pathname.new("#{TEST_FIXTURE_DIR}/rubocop@x.x.x.rbi") }
    let(:typecheck) { described_class.new([]) }

    before do
      allow(Dir).to receive(:glob).and_return([rbi_file.to_s])
    end

    it "trims RuboCop RBI file to only include allowlisted classes" do
      old_content = rbi_file.read

      typecheck.trim_rubocop_rbi(path: rbi_file.to_s)

      new_content = rbi_file.read

      expect(new_content).to include("RuboCop::Config")
      expect(new_content).to include("RuboCop::Cop::Base")
      expect(new_content).to include("Parser::Source")
      expect(new_content).to include("VERSION")
      expect(new_content).to include("SOME_CONSTANT")
      expect(new_content).not_to include("SomeUnusedCop")
      expect(new_content).not_to include("UnusedModule")
      expect(new_content).not_to include("CompletelyUnrelated")

      rbi_file.write(old_content)
    end
  end

  describe "#remove_dead_code" do
    let(:typecheck) { described_class.new([]) }
    let(:spoom_output) do
      <<~OUTPUT
        Candidates:
          Foo::Bar#qux cmd/foo.rb:20:2-22:5
          Foo::Bar#baz cmd/foo.rb:10:2-12:5
          Other#thing cmd/bar.rb:5:0-7:3

          Found 3 dead candidates
      OUTPUT
    end

    before do
      allow(Utils).to receive(:popen_read).and_return(spoom_output)
    end

    it "removes locations from the bottom of each file upwards" do
      removed = []
      allow(Utils).to receive(:safe_popen_read) { |*args, **| removed << args.last }

      typecheck.remove_dead_code

      expect(removed).to eq(["cmd/foo.rb:20:2-22:5", "cmd/foo.rb:10:2-12:5", "cmd/bar.rb:5:0-7:3"])
    end

    it "skips locations Spoom fails to remove without raising" do
      allow(Utils).to receive(:safe_popen_read) do |*args, **|
        raise ErrorDuringExecution.new(args, status: 1) if args.last == "cmd/foo.rb:10:2-12:5"
      end

      expect { typecheck.remove_dead_code }.to output(%r{  cmd/foo\.rb:10:2-12:5}).to_stdout
    end

    it "does not remove anything when no dead code is found" do
      allow(Utils).to receive(:popen_read).and_return("No dead code found!\n")

      expect(Utils).not_to receive(:safe_popen_read)

      typecheck.remove_dead_code
    end
  end
end
