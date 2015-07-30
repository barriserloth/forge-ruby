require 'spec_helper'

describe PuppetForge::V3::Module do
  before do
    stub_api_for(PuppetForge::V3::Module) do |stubs|
      stub_fixture(stubs, :get, '/v3/modules/puppetlabs-apache')
      stub_fixture(stubs, :get, '/v3/modules/absent-apache')
    end
  end

  describe '::find' do
    let(:mod) { PuppetForge::V3::Module.find('puppetlabs-apache') }
    let(:missing_mod) { PuppetForge::V3::Module.find('absent-apache') }

    it 'can find modules that exist' do
      expect(mod.name).to eq('apache')
    end

    it 'returns nil for non-existent modules' do
      expect(missing_mod).to be_nil
    end
  end

  describe '#owner' do
    let(:mod) { PuppetForge::V3::Module.find('puppetlabs-apache') }

    before do
      stub_api_for(PuppetForge::V3::User) do |stubs|
        stub_fixture(stubs, :get, '/v3/users/puppetlabs')
      end
    end

    it 'exposes the related module as a property' do
      expect(mod.owner).to_not be nil
    end

    it 'grants access to module attributes without an API call' do
      expect(PuppetForge::V3::User).not_to receive(:request)
      expect(mod.owner.username).to eql('puppetlabs')
    end

    it 'transparently makes API calls for other attributes' do
      expect(PuppetForge::V3::User).to receive(:request).once.and_call_original
      expect(mod.owner.created_at).to_not be nil
    end
  end

  describe '#current_release' do
    let(:mod) { PuppetForge::V3::Module.find('puppetlabs-apache') }

    it 'exposes the current_release as a property' do
      expect(mod.current_release).to_not be nil
    end

    it 'grants access to release attributes without an API call' do
      expect(PuppetForge::V3::Release).not_to receive(:request)
      expect(mod.current_release.version).to_not be nil
    end

  end

  describe '#releases' do
    let(:mod) { PuppetForge::V3::Module.find('puppetlabs-apache') }

    before do
      stub_api_for(PuppetForge::V3::Release) do |stubs|
        stub_fixture(stubs, :get, '/v3/releases/puppetlabs-apache-0.0.1')
        stub_fixture(stubs, :get, '/v3/releases/puppetlabs-apache-0.0.2')
        stub_fixture(stubs, :get, '/v3/releases/puppetlabs-apache-0.0.3')
        stub_fixture(stubs, :get, '/v3/releases/puppetlabs-apache-0.0.4')
        stub_fixture(stubs, :get, '/v3/releases/puppetlabs-apache-0.1.1')
        stub_fixture(stubs, :get, '/v3/releases?module=puppetlabs-apache')
      end
    end

    it 'exposes the related releases as a property' do
      expect(mod.releases).to be_an Array
    end

    it 'knows the size of the collection' do
      expect(mod.releases).to_not be_empty
    end

    it 'grants access to release attributes without an API call' do
      expect(PuppetForge::V3::Release).not_to receive(:request)
      expect(mod.releases.map(&:version)).to_not include nil
    end

    it 'loads releases lazily' do
      versions = %w[ 0.0.1 0.0.2 0.0.3 0.0.4 0.1.1 ]

      expect(PuppetForge::V3::Release).to receive(:find).exactly(5).times.and_call_original

      releases = mod.releases

      expect(releases.map(&:created_at)).to_not include nil
    end

    it 'transparently makes API calls for other attributes' do
      expect(PuppetForge::V3::Release).to receive(:where) \
                        .once.and_call_original
      releases = mod.releases
    end
  end

  describe 'instance properies' do
    let(:mod) { PuppetForge::V3::Module.find('puppetlabs-apache') }

    example 'are easily accessible' do
      expect(mod.created_at).to_not be nil
    end
  end
end
