describe MetadataJsonLint do
  describe '.parse' do
    def fixture(name)
      File.expand_path("../tests/#{name}/metadata.json", __dir__)
    end

    context 'with strict_dependencies set in the block' do
      it do
        expect do
          expect(described_class.parse(fixture('open_ended_dependency')) { |o| o.strict_dependencies = true }).to be(false)
        end.to output(/open ended dependency version requirement/).to_stdout
      end
    end

    context 'with strict_puppet_version set in the block' do
      it do
        expect do
          expect(described_class.parse(fixture('requirements_eol_version')) { |o| o.strict_puppet_version = true }).to be(false)
        end.to output(/is no longer supported/).to_stdout
      end
    end

    context 'with json format set in the block' do
      it do
        expect do
          described_class.parse(fixture('bad_license')) { |o| o.format = :json }
        end.to output(/"warnings":\[\{"check":"license","msg":"License identifier/).to_stdout
      end
    end
  end

  describe '.validate_requirements!' do
    context 'empty requirements' do
      let :requirements do
        []
      end

      it { expect { described_class.validate_requirements!(requirements) }.not_to raise_error }
    end

    context 'with openvox' do
      let :requirements do
        [
          { 'name' => 'openvox', 'version_requirement' => '>= 7.0.0 < 9.0.0' },
        ]
      end

      it { expect { described_class.validate_requirements!(requirements) }.not_to raise_error }
    end

    context 'with openvox and puppet' do
      let :requirements do
        [
          { 'name' => 'puppet', 'version_requirement' => '>= 6.0.0 < 8.0.0' },
          { 'name' => 'openvox', 'version_requirement' => '>= 7.0.0 < 9.0.0' },
        ]
      end

      it { expect { described_class.validate_requirements!(requirements) }.not_to raise_error }
    end

    context 'with pe' do
      let :requirements do
        [
          { 'name' => 'pe' },
        ]
      end

      it do
        expect(described_class).to receive('warn').with(:requirements,
                                                        "The 'pe' requirement is no longer supported by the Forge.")
        expect { described_class.validate_requirements!(requirements) }.not_to raise_error
      end
    end

    context 'with invalid requirement' do
      let :requirements do
        [
          { 'name' => 'puppet', 'version_requirement' => 'a' },
        ]
      end

      it do
        expect(described_class).to receive('error').with(:requirements,
                                                         "Invalid 'version_requirement' field in metadata.json: Unparsable version range: \"a\"")
        expect { described_class.validate_requirements!(requirements) }.not_to raise_error
      end
    end
  end
end
