# frozen_string_literal: true

RSpec.describe PubidCheck do
  describe ".verify!" do
    it "passes when pubid parses every sample id" do
      expect { described_class.verify! }.not_to raise_error
    end

    it "aborts when pubid raises on parse" do
      allow(Pubid::Iso::Identifier).to receive(:parse)
        .and_raise(NameError, "uninitialized constant Pubid::Parg::Backend::Parsanol")

      expect { described_class.verify! }
        .to raise_error(SystemExit)
        .and output(/pubid cannot parse `ISO 1:2002`.*Parsanol/).to_stderr
    end

    it "aborts when pubid round-trips an id to a different string" do
      allow(Pubid::Iso::Identifier).to receive(:parse)
        .and_return(double(to_s: "ISO 1"))

      expect { described_class.verify! }
        .to raise_error(SystemExit)
        .and output(/pubid cannot parse `ISO 1:2002`.*got `ISO 1`/).to_stderr
    end
  end
end
