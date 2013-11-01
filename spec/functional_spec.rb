require 'spec_helper'

feature 'ODLanding App Functionality' do
  include Mail::Matchers

  before :each do
    Mail::TestMailer.deliveries.clear
    visit '/o/landing'
  end

  given(:valid_title) { 'Application Title' }
  given(:valid_desc) { 'More than 50 char long Application Description goes here.' }
  given(:valid_email) { 'test@example.com' }

  context 'valid submission', js: true do
    scenario 'with valid data' do
      within('.the-form') do
        fill_in :title, with: valid_title
        fill_in :desc, with: valid_desc
        fill_in :email, with: valid_email
      end

      click_button 'Get Applications Fast'
      expect(page).to have_content 'Thank you for submitting your job!'

      should have_sent_email
      should have_sent_email.from('odysseas@odesk.com')
      should have_sent_email.to(app.settings.sendto)
    end
  end

  context 'invalid submission', js: true do
    scenario 'with empty title' do
      within('.the-form') do
        fill_in :desc, with: valid_desc
        fill_in :email, with: valid_email
      end

      click_button 'Get Applications Fast'
      expect(page).to have_content 'Project title field is required.'

      should_not have_sent_email
    end

    scenario 'with empty desc' do
      within('.the-form') do
        fill_in :title, with: valid_title
        fill_in :email, with: valid_email
      end

      click_button 'Get Applications Fast'
      expect(page).to have_content 'Project description is too short (minimum 50 chars long).'

      should_not have_sent_email
    end

    scenario 'with small length desc' do
      within('.the-form') do
        fill_in :title, with: valid_title
        fill_in :desc, with: 'abc'
        fill_in :email, with: valid_email
      end

      click_button 'Get Applications Fast'
      expect(page).to have_content 'Project description is too short (minimum 50 chars long).'

      should_not have_sent_email
    end

    scenario 'with empty email' do
      within('.the-form') do
        fill_in :title, with: valid_title
        fill_in :desc, with: valid_desc
      end

      click_button 'Get Applications Fast'
      expect(page).to have_content 'Email field is required.'

      should_not have_sent_email
    end
  end
end
