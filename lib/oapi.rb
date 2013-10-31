require 'httparty'

class OApi
  include HTTParty

  base_uri 'https://www.odesk.com/api/o2/v1'

  def self.profiles(q, rate='*')
    data = {
      q: q,
      hl: 1,
      profile_access: 'public',
      paging: '0;20'
    }

    out = {
      profiles: [],
      count: 0
    }

    unless rate.nil? or rate.blank?
      data[:rate] = "[* TO #{rate}]"
    end

    response = get('/search/*/profiles.json', query: { data: data.to_json })

    proxy = response["proxy"]

    return out if proxy.nil? || proxy["data"].nil?

    out[:count] = proxy["paging"]["total"]

    proxy["data"].each do |p|
      profile_hl = p["hl"]
      profile_data = p["data"]

      skills = []
      unless profile_data["skills"].nil?
        skills = profile_data["skills"].map { |s| s["skl_name"] }.slice(0, 4)
      end

      title = unless profile_hl.nil? or profile_hl["title"].nil?
                profile_hl["title"].first
              else
                profile_data["dev_profile_title"]
              end

      blurb = unless profile_hl.nil? or profile_hl["blurb"].nil?
                profile_hl["blurb"].first
              else
                profile_data["dev_blurb"]
              end

      out[:profiles] << {
        title: title,
        desc: blurb,
        skills: skills,
        name: profile_data["dev_short_name"],
        country: profile_data["dev_country"],
        rate: profile_data["dev_bill_rate"],
        hash: profile_data["dev_recno_ciphertext"],
        portrait_50: profile_data["dev_portrait_50"]
      }
    end

    out
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
