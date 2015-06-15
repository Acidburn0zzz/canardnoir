accs = @affiliated_committers.reject { |acc| !organization_affiliated_committers_stats(@stats_map[acc.id]) }

xml.instruct!
xml.response do
  xml.status 'success'
  xml.items_returned accs.size
  xml.items_available accs.size
  xml.first_item_position 0
  xml.result do
    xml.affiliated_committers do
      accs.each do |acc|
        stats = organization_affiliated_committers_stats(@stats_map[acc.id])

        xml.affiliator do
          xml.name acc.name
          xml.kudos acc.person.kudo_rank
          xml.level FOSSerBadge.new(acc, positions_count: acc.positions.count).level
          xml.most_commits do
            xml.project stats[:most_committed_project].name
            xml.commits stats[:max_commits]
          end
          xml.most_recent_commit do
            xml.project stats[:most_recent_project].name
            xml.date stats[:last_checkin].to_date.to_s(:by) if stats[:last_checkin]
          end
        end
      end
      xml.detailed_page_url "/orgs/#{@organization.url_name}/affiliated_committers"
    end
  end
end
