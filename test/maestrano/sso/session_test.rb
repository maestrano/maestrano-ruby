require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module SSO
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
  
      context "remote_check_required?" do
        setup do
          @sso_session = Maestrano::SSO::Session.new(@session)
        end
  
        should "should return true if uid is missing" do
          @sso_session.uid = nil
          assert @sso_session.remote_check_required?
        end
    
        should "should return true if session_token is missing" do
          @sso_session.session_token = nil
          assert @sso_session.remote_check_required?
        end
    
        should "should return true if recheck is missing" do
          @sso_session.recheck = nil
          assert @sso_session.remote_check_required?
        end
    
        should "return true if now is after recheck" do
          Timecop.freeze(@sso_session.recheck + 60) do
            assert @sso_session.remote_check_required?
          end
        end
    
        should "return false if now is before recheck" do
          Timecop.freeze(@sso_session.recheck - 60) do
            assert !@sso_session.remote_check_required?
          end
        end
      end
  
      context "perform_remote_check" do
        setup do
          @sso_session = Maestrano::SSO::Session.new(@session)
        end
  
        should "update the session recheck and return true if valid" do
          recheck = @sso_session.recheck + 600
          RestClient.stubs(:get).returns({'valid' => true, 'recheck' => recheck.utc.iso8601 }.to_json)
          assert @sso_session.perform_remote_check
          assert_equal @sso_session.recheck, recheck
        end
    
        should "leave the session recheck unchanged and return false if invalid" do
          recheck = @sso_session.recheck
          RestClient.stubs(:get).returns({'valid' => false, 'recheck' => (recheck + 600).utc.iso8601 }.to_json)
          assert !@sso_session.perform_remote_check
          assert_equal @sso_session.recheck, recheck
        end
      end
  
      context "valid?" do
        setup do
          @sso_session = Maestrano::SSO::Session.new(@session)
        end
  
        should "return true if no remote_check_required?" do
          @sso_session.stubs(:remote_check_required?).returns(false)
          assert @sso_session.valid?
        end
    
        should "return true if remote_check_required? and valid" do
          @sso_session.stubs(:remote_check_required?).returns(true)
          @sso_session.stubs(:perform_remote_check).returns(true)
          assert @sso_session.valid?
        end
    
        should "update session recheck timestamp if remote_check_required? and valid" do
          recheck = (@sso_session.recheck + 600)
          @sso_session.recheck = recheck
          @sso_session.stubs(:remote_check_required?).returns(true)
          @sso_session.stubs(:perform_remote_check).returns(true)
          @sso_session.valid?
          assert_equal @session[:mno_session_recheck], recheck.utc.iso8601
        end
    
        should "return false if remote_check_required? and invalid" do
          @sso_session.stubs(:remote_check_required?).returns(true)
          @sso_session.stubs(:perform_remote_check).returns(false)
          assert !@sso_session.valid?
        end
      end
  
    end
  end
end