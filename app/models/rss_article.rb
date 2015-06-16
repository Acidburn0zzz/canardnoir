class RssArticle < ActiveRecord::Base
  belongs_to :rss_feed
  validates :guid, presence: true
  validates :title, presence: true

  class << self
    def from_item(item)
      RssArticle.new(title: item.title, link: item.link, description: item.description, author: set_author(item),
                     time: set_time(item), guid: set_guid(item))
    end

    def set_author(item)
      item.name || item.author || item.dc_creator
    end

    def set_time(item)
      date = (item.published || item.pubDate || item.dc_date || Time.current).to_s
      time = Time.parse(date).utc
      time = Time.current if time > Time.current
      time
    end

    def set_guid(item)
      item.guid || item.guid = "#{item.title}|#{item.link}|#{item.description}".hash
    end
  end
end
