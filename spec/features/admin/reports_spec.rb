require "spec_helper"

feature %q{
    As an administrator
    I want numbers, all the numbers!
} do
  include AuthenticationWorkflow
  include WebHelper


  scenario "orders and distributors report" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Orders And Distributors'

    page.should have_content 'Order date'
  end

  scenario "bulk co-op report" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Bulk Co-Op'

    page.should have_content 'Supplier'
  end

  scenario "payments reports" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Payment Reports'

    page.should have_content 'Payment State'
  end

  scenario "orders & fulfillment reports" do
    login_to_admin_section
    click_link 'Reports'
    click_link 'Orders & Fulfillment Reports'

    page.should have_content 'Supplier'
  end

  scenario "orders & fulfillment reports are precise to time of day, not just date" do
    # Given two orders on the same day at different times
    @bill_address = create(:address)
    @distributor_address = create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234")
    @distributor = create(:distributor_enterprise, :address => @distributor_address)
    product = create(:product)
    product_distribution = create(:product_distribution, :product => product, :distributor => @distributor)
    @shipping_instructions = "pick up on thursday please!"
    @order1 = create(:order, :distributor => @distributor, :bill_address => @bill_address, :special_instructions => @shipping_instructions)
    @order2 = create(:order, :distributor => @distributor, :bill_address => @bill_address, :special_instructions => @shipping_instructions)

    Timecop.travel(Time.zone.local(2013, 4, 25, 14, 0, 0)) { @order1.finalize! }
    Timecop.travel(Time.zone.local(2013, 4, 25, 16, 0, 0)) { @order2.finalize! }

    create(:line_item, :product => product, :order => @order1)
    create(:line_item, :product => product, :order => @order2)

    # When I generate a customer report with a timeframe that includes one order but not the other
    login_to_admin_section
    click_link 'Reports'
    click_link 'Orders & Fulfillment Reports'

    fill_in 'q_completed_at_gt', with: '2013-04-25 13:00:00'
    fill_in 'q_completed_at_lt', with: '2013-04-25 15:00:00'
    select 'Order Cycle Customer Totals', from: 'report_type'
    click_button 'Search'

    # Then I should see the rows for the first order but not the second
    all('table#listing_orders tbody tr').count.should == 2 # Two rows per order
  end

  describe "products and inventory report" do
    it "shows products and inventory report" do
      login_to_admin_section
      click_link 'Reports'

      page.should have_content "All products"
      page.should have_content "Inventory (on hand)"
      click_link 'Products & Inventory'
      page.should have_content "Supplier"
    end
  end

end
