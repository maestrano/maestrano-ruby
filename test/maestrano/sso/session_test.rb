require File.expand_path('../../../test_helper', __FILE__)

class SessionTest < Test::Unit::TestCase
  setup do
    @session = {
      mno_uid: 'usr-1',
      mno_session: 'g4dfg4fdg8378d6acf45',
      mno_session_recheck: Time.now.utc.iso8601
    }
  end
  
  should "initialize the sso session properly" do
    sso_session = Maestrano::SSO::Session.new(@session)
    assert_equal sso_session.uid, @session[:mno_uid]
    assert_equal sso_session.session_token, @session[:mno_session]
    assert_equal sso_session.recheck, Time.iso8601(@session[:mno_session_recheck])
  end
end