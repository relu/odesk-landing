require 'httparty'
require 'pp'

class OApi
  include HTTParty

  base_uri 'https://www.odesk.com/api/o2/v1/search'

  def self.profiles(q)
    data = {
      q: q,
      paging: '0;20'
    }

    response = get('/*/profiles.json', query: { data: data.to_json })

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
          rate: profile["dev_pay_rate"],
          portrait_50: profile["dev_portrait_50"]
        }
      end
    end
  end

  def self.build_q(query=nil, title=nil, skill=nil, subcategory=nil)
    q = ''
    q = "#{query} " unless query.nil? or query.blank?
    q += "title:#{title} " unless title.nil? or title.blank?
    q += "skills:#{skill} " unless skill.nil? or skill.blank?
    q += "subcategory:#{subcategory}" unless subcategory.nil? or subcategory.blank?
    q.strip!
  end
end
