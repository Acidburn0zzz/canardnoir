require 'test_helper'

describe 'AuthenticationsController' do
  let(:account) { create(:account) }
  let(:account_params) do
    FactoryBot.attributes_for(:account).select do |k, _v|
      %w(login email password).include?(k.to_s)
    end
  end

  describe 'new' do
    it 'must redirect to the login page for users who have not logged in' do
      get :new

      must_respond_with :redirect
      must_redirect_to new_session_path
    end

    it 'must render new page correctly for new users' do
      login_as account
      account.verifications.delete_all

      get :new

      must_respond_with :ok
      assigns(:account).must_be :present?
      assigns(:account).firebase_verification.must_be :present?
    end

    it 'wont allow access to verified users' do
      login_as account

      get :new

      must_redirect_to root_path
    end
  end

  describe 'github_callback' do
    let(:expected_attributes) { { unique_id: 'notalex', token: 'e068fc1968fakef5c7e7fake6369336fake4bab9' } }

    it 'must create an account using github' do
      VCR.use_cassette('GithubVerification') do
        assert_difference('Account.count', 1) do
          get :github_callback, code: Faker::Lorem.word
        end

        request.env[:clearance].current_user.id.must_equal Account.last.id
        must_redirect_to Account.last
      end
    end

    it 'must redirect back to path stored in session after github signup' do
      session[:return_to] = projects_path
      github_stub = stub(email: Faker::Internet.email, login: Faker::Name.first_name, access_token: Faker::Lorem.word)
      @controller.stubs(:github_api).returns(github_stub)

      assert_difference('Account.count') do
        get :github_callback, code: Faker::Lorem.word
      end

      must_redirect_to projects_path
    end

    it 'must create verification for logged in user' do
      session[:return_to] = projects_path
      login_as account
      account.verifications.delete_all
      github_stub = stub(email: account.email, login: account.login, access_token: Faker::Lorem.word)
      @controller.stubs(:github_api).returns(github_stub)

      assert_no_difference('Account.count') do
        get :github_callback, code: Faker::Lorem.word
      end

      account.reload
      must_redirect_to projects_path
      flash[:notice].must_equal I18n.t('verification_completed')
      account.github_verification.must_be :present?
    end

    it 'must show errors when github verification fails for logged in user' do
      login_as account
      account.verifications.delete_all
      github_stub = stub(email: account.email, login: account.login, access_token: '')
      @controller.stubs(:github_api).returns(github_stub)

      assert_no_difference('Account.count') do
        get :github_callback, code: Faker::Lorem.word
      end

      account.reload
      must_redirect_to new_authentication_path
      error_messages = account.errors.messages[:'github_verification.token']
      error_messages.must_be :present?
      flash[:notice].must_equal error_messages.last
    end

    it 'must display errors when github signup fails for new user' do
      github_stub = stub(email: Faker::Internet.email, login: Faker::Lorem.word, access_token: '')
      @controller.stubs(:github_api).returns(github_stub)

      assert_no_difference('Account.count') do
        get :github_callback, code: Faker::Lorem.word
      end

      must_redirect_to new_account_path
      flash[:notice].must_match(/can't be blank/)
    end

    it 'must assign a random password and set activated_at for new github user' do
      github_stub = stub(email: Faker::Internet.email, login: Faker::Name.first_name, access_token: Faker::Lorem.word)
      @controller.stubs(:github_api).returns(github_stub)

      assert_difference('Account.count', 1) do
        get :github_callback, code: Faker::Lorem.word
      end

      account = Account.last
      account.encrypted_password.must_be :present?
      account.activated_at.must_be :present?
      account.login.must_equal github_stub.login
    end

    it 'must assign a random login when github login already exists' do
      github_stub = stub(email: Faker::Internet.email, login: account.login, access_token: Faker::Lorem.word)
      @controller.stubs(:github_api).returns(github_stub)

      assert_difference('Account.count', 1) do
        get :github_callback, code: Faker::Lorem.word
      end

      new_account = Account.last
      new_account.login.must_match account.login
      new_account.login.wont_equal account.login
    end

    it 'must fix github login if it begins with a number' do
      github_stub = stub(email: Faker::Internet.email, login: '007', access_token: Faker::Lorem.word)
      @controller.stubs(:github_api).returns(github_stub)

      assert_difference('Account.count', 1) do
        get :github_callback, code: Faker::Lorem.word
      end

      account = Account.last
      account.login.must_match github_stub.login
    end

    it 'must modify login if default github login is less than 3 chars' do
      github_stub = stub(email: Faker::Internet.email, login: 'xy', access_token: Faker::Lorem.word)
      @controller.stubs(:github_api).returns(github_stub)

      assert_difference('Account.count', 1) do
        get :github_callback, code: Faker::Lorem.word
      end

      new_account = Account.last
      new_account.login.must_match(/xy\d+/)
    end

    describe 'redirect_matching_account' do
      it 'must sign in an existing user through github' do
        github_stub = stub(email: account.email, login: account.login, access_token: Faker::Lorem.word)
        @controller.stubs(:github_api).returns(github_stub)

        get :github_callback, code: Faker::Lorem.word

        account.reload
        must_redirect_to account
        request.env[:clearance].current_user.id.must_equal account.id
        account.github_verification.token.must_equal github_stub.access_token
      end

      it 'must create a github verification record for a matching unverified account' do
        account.github_verification.destroy
        github_stub = stub(email: account.email, login: account.login, access_token: Faker::Lorem.word)
        @controller.stubs(:github_api).returns(github_stub)

        get :github_callback, code: Faker::Lorem.word

        account.reload
        account.github_verification.token.must_equal github_stub.access_token
        account.github_verification.unique_id.must_equal github_stub.login
      end

      it 'must activate email for a matching github email' do
        account.update! activated_at: nil, activation_code: Faker::Lorem.word
        github_stub = stub(email: account.email, login: account.login, access_token: Faker::Lorem.word)
        @controller.stubs(:github_api).returns(github_stub)

        get :github_callback, code: Faker::Lorem.word

        account.reload
        account.access.activated_at.must_be :present?
        account.access.activation_code.must_be_nil
      end

      it 'must refresh github verification token and unique_id on every login' do
        new_access_token = Faker::Internet.password
        new_login = Faker::Name.first_name
        github_stub = stub(email: account.email, login: new_login, access_token: new_access_token)
        @controller.stubs(:github_api).returns(github_stub)

        get :github_callback, code: Faker::Lorem.word

        account.reload
        account.github_verification.token.must_equal new_access_token
        account.github_verification.unique_id.must_equal new_login
      end

      it 'must handle github login failure' do
        github_stub = stub(email: account.email, login: '', access_token: '')
        @controller.stubs(:github_api).returns(github_stub)

        get :github_callback, code: Faker::Lorem.word

        must_redirect_to new_session_path
        flash[:notice].must_equal I18n.t('github_sign_in_failed')
      end
    end
  end

  describe 'firebase_callback' do
    it 'must create verification record for existing account' do
      account.verifications.destroy_all
      login_as account
      firebase_token = [{ 'user_id' => Faker::Internet.password }]
      FirebaseService.any_instance.stubs(:decode).returns(firebase_token)

      auth_params = { 'firebase_verification_attributes' => { 'credentials' => Faker::Lorem.word } }

      get :firebase_callback, account: auth_params

      account.reload
      must_redirect_to account
      account.firebase_verification.must_be :present?
    end

    it 'must handle verification failure for existing record' do
      account.verifications.destroy_all
      login_as account
      firebase_token = [{ 'user_id' => '' }]
      FirebaseService.any_instance.stubs(:decode).returns(firebase_token)

      auth_params = { 'firebase_verification_attributes' => { 'credentials' => Faker::Lorem.word } }

      get :firebase_callback, account: auth_params

      account.reload
      must_redirect_to new_authentication_path
      flash[:notice].must_be :present?
    end
  end
end
