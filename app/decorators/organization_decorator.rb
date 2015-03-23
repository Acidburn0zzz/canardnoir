class OrganizationDecorator < Cherry::Decorator
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def sidebar
    [
      [
        [:org_summary,    I18n.t(:organization_summary),     h.organization_path(organization)],
        [:settings,       I18n.t(:settings),                 h.settings_organization_path(organization)],
        [:widgets,        I18n.t(:widget),                   h.organization_organization_widgets_path(organization)]
      ],
      [
        [:code_data,      I18n.t(:project_portfolio)],
        [:projects,       I18n.t(:claimed_projects),         h.projects_organization_path(organization)]
      ]
    ]
  end

  def icon(size = :small, opts = {})
    Icon.new(organization, context: { size: size, opts: opts }).image(with_dimensions: false)
  end

  class << self
    def select_options
      options = Organization.active.order('lower(name)').pluck(:name, :id)
      options.unshift(['Unaffiliated', ''])
      options.push(['Other', ''])
    end
  end
end
