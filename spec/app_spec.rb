require 'spec_helper'

describe 'ODLanding App' do
  describe 'form submit' do
    include Mail::Matchers

    let(:valid_title) { 'Application Title' }
    let(:valid_desc) { 'More than 50 char long Application Description goes here.' }
    let(:valid_email) { 'test@example.com' }

    before do
      Mail.defaults do
        delivery_method :test
      end

      get '/o/landing'
      post '/send', {
        title: valid_title,
        desc: valid_desc,
        scroll_count: 5,
        email: valid_email
      }
    end

    it { should have_sent_email }
    it { should have_sent_email.from('odysseas@odesk.com') }
    it { should have_sent_email.to(app.settings.sendto) }
    it { should have_sent_email.with_subject("Landing Page - #{valid_email} - #{valid_title}") }
    it { should have_sent_email.matching_body(valid_desc) }
  end
end
