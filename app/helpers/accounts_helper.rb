module AccountsHelper
  def notification_type_text(notification_type)
    case notification_type
    when :kudo then t('accounts.unsubscribe_emails.kudo_notification_type')
    when :post then t('accounts.unsubscribe_emails.post_notification_type')
    else t('accounts.unsubscribe_emails.default_notification_type')
    end
  end

  def privacy_policy_link
    link_to(t('accounts.unsubscribe_emails.privacy_policy'), 'http://blog.openhub.net/privacy', target: '_blank')
  end

  def privacy_settings_text(account = nil)
    t('accounts.unsubscribe_emails.privacy_html', privacy_settings_link: privacy_settings_link(account))
  end

  def active_code_location(url)
    /^git@github.com:(.+)\.git/ =~ url

    urls = ["'git://github.com/#{$1}'", "'git://github.com/#{$1}.git'"].join(',')

    Repository.where("trim(trailing '/' from url) in (#{urls})").count > 0
  end

  private

  def privacy_settings_link(account)
    url = account ? edit_account_privacy_account_path(account) : new_session_path
    link_to(t('accounts.unsubscribe_emails.settings'), url)
  end
end
