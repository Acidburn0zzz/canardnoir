require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  let(:org) { create(:organization) }

  it 'unclaims projects when destroyed and reclaims them when undestroyed' do
    proj1 = create(:project)
    proj2 = create(:project)
    proj1.update_attributes(organization_id: org.id)
    proj2.update_attributes(organization_id: org.id)
    pe1 = PropertyEdit.where(target: proj1, key: 'organization_id', value: org.id.to_s).first
    pe2 = PropertyEdit.where(target: proj2, key: 'organization_id', value: org.id.to_s).first
    pe1.undone.must_equal false
    pe2.undone.must_equal false
    org.destroy
    pe1.reload.undone.must_equal true
    pe2.reload.undone.must_equal true
    proj1.reload.organization_id.must_equal nil
    proj2.reload.organization_id.must_equal nil
    CreateEdit.where(target: org).first.redo!(create(:admin))
    pe1.reload.undone.must_equal false
    pe2.reload.undone.must_equal false
    proj1.reload.organization_id.must_equal org.id
    proj2.reload.organization_id.must_equal org.id
  end

  describe 'managed_by' do
    it 'should return all orgs managed by an account' do
      account = create(:account)
      create(:manage, account: account, target: org)
      Organization.managed_by(account).must_equal [org]
    end
  end
end