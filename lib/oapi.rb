require 'httparty'
require 'pp'

class OApi
  include HTTParty

  base_uri 'https://www.odesk.com/api/o2/v1'

  def self.profiles(q, rate='*')
    data = {
      q: q,
      rate: "[* TO #{rate}]",
      paging: '0;20'
    }

    response = get('/search/*/profiles.json', query: { data: data.to_json })

    return [] if response["proxy"].nil? || response["proxy"]["data"].nil?

    [].tap do |profiles|
      response["proxy"]["data"].each do |p|
        profile = p["data"]

        skills = []
        unless profile["skills"].nil?
          skills = profile["skills"].map { |s| s["skl_name"] }.slice(0, 4)
        end

        profiles << {
          title: profile["dev_profile_title"],
          desc: profile["dev_blurb"],
          skills: skills,
          name: profile["dev_short_name"],
          country: profile["dev_country"],
          rate: profile["dev_bill_rate"],
          hash: profile["dev_recno_ciphertext"],
          portrait_50: profile["dev_portrait_50"]
        }
      end
    end
  end

  def self.suggestions(q)
    data = {
      q: q
    }

    response = get('/associations/*/search/contractors.json', query: { data: data.to_json })

    return [] if response["proxy"].nil? || response["proxy"]["suggestions"].nil?

    [].tap do |suggestions|
      response["proxy"]["suggestions"].each do |s|
        suggestions << s.gsub(/<[^>]+>/, '')
      end
    end
  end

  def self.build_q(params)
    q = ''
    q += "#{params[:query]} " unless params[:query].nil? or params[:query].blank?

    %i(title skills subcategory country).each do |key|
      q += "#{key.to_s}:#{params[key]} " unless params[key].nil? or params[key].blank?
    end

    q.strip!
  end
end
