require 'test_helper'

class GithubUserTest < ActiveSupport::TestCase
  it 'must use url as username' do
    github_user = GithubUser.new(url: 'stan')
    github_user.username.must_equal 'stan'
  end

  describe 'valid?' do
    it 'wont be valid for invalid username' do
      username = 'github.com/stan'
      github_user = GithubUser.new(url: username)
      github_user.wont_be :valid?
      github_user.errors.messages[:url].first.must_equal I18n.t('invalid_github_username')
    end

    it 'wont be valid when username does not exist on github' do
      username = 'invalid_github'
      output = { message: 'Not Found', documentation_url: 'https://developer.github.com/v3' }.to_json
      Open3.stubs(:popen3).returns [nil, output]
      github_user = GithubUser.new(url: username)
      github_user.valid?
      github_user.errors.messages[:url].first.must_equal I18n.t('invalid_github_username')
    end
  end

  describe 'save!' do
    before do
      Repository.any_instance.stubs(:bypass_url_validation).returns(true)
    end

    it 'must create repositories from given username' do
      stub_github_user_repositories_call do
        Repository.count.must_equal 0

        @github_user = GithubUser.new(url: 'stan')
        @github_user.save!

        Repository.count.must_equal 4
      end
    end
  end
end
