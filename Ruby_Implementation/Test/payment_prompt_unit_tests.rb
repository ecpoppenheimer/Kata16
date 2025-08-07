# frozen_string_literal: true

require "tty-prompt"
require "tty/prompt/test"
require 'rspec/autorun'
require '../payment'
require '../database'

describe Payment do
  # Setup.  Configure prompt as a test object, rather than a normal prompt
  let(:prompt) {TTY::Prompt::Test.new}
  let(:db) {Database.new}

  it "A valid kwarg set can be collected from a prompt" do
    # Pre-fill prompt inputs
    prompt.input.puts "7.5"
    prompt.input.rewind

    expect(Payment.kwargs_from_prompt(prompt, {})[:value]).to eql(7.5)
  end

  it "Feeding a negative for the price is invalid" do
    # Pre-fill prompt inputs
    prompt.input.puts "-3"
    prompt.input.rewind

    expect(Payment.kwargs_from_prompt(prompt, {})[:value]).to eql(5.0) # 5.0 is the default value
  end

  it "Can construct a valid object" do
    # Pre-fill prompt inputs
    prompt.input.puts "7.5"
    prompt.input.rewind

    expect(prompted_payment_factory(Payment, prompt, db).value).to eql(7.5)
  end

  it "Respects fed default values" do
    # Pre-fill prompt inputs
    prompt.input.puts ""
    prompt.input.rewind

    expect(prompted_payment_factory(Payment, prompt, db, {value: 12.75}).value).to eql(12.75)
  end
end

describe PhysicalProduct do
  # Setup.  Configure prompt as a test object, rather than a normal prompt
  let(:prompt) {TTY::Prompt::Test.new}
  let(:db) {Database.new}

  it "A valid kwarg set can be collected from a prompt" do
    # Pre-fill prompt inputs
    prompt.input.puts "1"
    prompt.input.puts "apple"
    prompt.input.puts "erics house"
    prompt.input.puts ""
    prompt.input.rewind

    kwargs = PhysicalProduct.kwargs_from_prompt(prompt, {})
    expect(kwargs[:value]).to eql(1.0)
    expect(kwargs[:product_id]).to eql("apple")
    expect(kwargs[:shipping_address]).to eql("erics house")
    expect(kwargs[:agent]).to be_nil
  end

  it "It can construct a valid object" do
    # Pre-fill prompt inputs
    prompt.input.puts "800"
    prompt.input.puts "laptop"
    prompt.input.puts "toms house"
    prompt.input.puts "john"
    prompt.input.rewind

    product = prompted_payment_factory(PhysicalProduct, prompt, db)
    expect(product.value).to eql(800.0)
    expect(product.product_id).to eql("laptop")
    expect(product.shipping_address).to eql("toms house")
    expect(product.agent).to eql("john")
  end

  it "Respects fed default values" do
    # Pre-fill prompt inputs
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.rewind

    defaults = {value: 756.12, product_id: "pear", shipping_address: "sams house", agent: "phil"}
    product = prompted_payment_factory(PhysicalProduct, prompt, db, defaults)
    expect(product.value).to eql(756.12)
    expect(product.product_id).to eql("pear")
    expect(product.shipping_address).to eql("sams house")
    expect(product.agent).to eql("phil")
  end

  it "Correctly overwrites defaults values" do
    # Pre-fill prompt inputs
    prompt.input.puts ""
    prompt.input.puts "tomato"
    prompt.input.puts "jimmys house"
    prompt.input.puts ""
    prompt.input.rewind

    defaults = {value: 756.12, product_id: "pear", shipping_address: "sams house", agent: "phil"}
    product = prompted_payment_factory(PhysicalProduct, prompt, db, defaults)
    expect(product.value).to eql(756.12)
    expect(product.product_id).to eql("tomato")
    expect(product.shipping_address).to eql("jimmys house")
    expect(product.agent).to eql("phil")
  end
end

describe Book do
  # Setup.  Configure prompt as a test object, rather than a normal prompt
  let(:prompt) {TTY::Prompt::Test.new}
  let(:db) {Database.new}

  it "A valid kwarg set can be collected from a prompt" do
    # Pre-fill prompt inputs
    prompt.input.puts "20"
    prompt.input.puts "harry potter"
    prompt.input.puts "erics house"
    prompt.input.puts ""
    prompt.input.rewind

    kwargs = Book.kwargs_from_prompt(prompt, {})
    expect(kwargs[:value]).to eql(20.0)
    expect(kwargs[:product_id]).to eql("harry potter")
    expect(kwargs[:shipping_address]).to eql("erics house")
    expect(kwargs[:agent]).to be_nil
  end

  it "It can construct a valid object" do
    # Pre-fill prompt inputs
    prompt.input.puts "20"
    prompt.input.puts "harry potter"
    prompt.input.puts "erics house"
    prompt.input.puts "john"
    prompt.input.rewind

    product = prompted_payment_factory(Book, prompt, db)
    expect(product.value).to eql(20.0)
    expect(product.product_id).to eql("harry potter")
    expect(product.shipping_address).to eql("erics house")
    expect(product.agent).to eql("john")
  end

  it "Respects fed defaults" do
    # Pre-fill prompt inputs
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.rewind

    defaults = {value: 19.99, product_id: "lord of the rings", shipping_address: "marys house", agent: "anne"}
    product = prompted_payment_factory(Book, prompt, db, defaults)
    expect(product.value).to eql(19.99)
    expect(product.product_id).to eql("lord of the rings")
    expect(product.shipping_address).to eql("marys house")
    expect(product.agent).to eql("anne")
  end
end

describe Membership do
  # Setup.  Configure prompt as a test object, rather than a normal prompt
  let(:prompt) {TTY::Prompt::Test.new}
  let(:db) {Database.new}

  it "A valid kwarg set can be collected from a prompt" do
    # Pre-fill prompt inputs
    prompt.input.puts "12"
    prompt.input.puts "cool people club"
    prompt.input.puts "rick"
    prompt.input.puts "1"
    prompt.input.rewind

    kwargs = Membership.kwargs_from_prompt(prompt, {})
    expect(kwargs[:value]).to eql(12.0)
    expect(kwargs[:membership_id]).to eql("cool people club")
    expect(kwargs[:member_id]).to eql("rick")
    expect(kwargs[:membership_payment_type]).to eql("activation")
  end

  it "It can construct a valid object" do
    # Pre-fill prompt inputs
    prompt.input.puts "12"
    prompt.input.puts "cool people club"
    prompt.input.puts "rick"
    prompt.input.puts "1"
    prompt.input.rewind

    product = prompted_payment_factory(Membership, prompt, db)
    expect(product.value).to eql(12.0)
    expect(product.membership_id).to eql("cool people club")
    expect(product.member_id).to eql("rick")
    expect(product.membership_payment_type).to eql("activation")
  end

  it "Can select 'upgrade' type with keypress '2'" do
    # Pre-fill prompt inputs
    prompt.input.puts "12"
    prompt.input.puts "cool people club"
    prompt.input.puts "rick"
    prompt.input.puts "2"
    prompt.input.rewind

    product = prompted_payment_factory(Membership, prompt, db)
    expect(product.value).to eql(12.0)
    expect(product.membership_id).to eql("cool people club")
    expect(product.member_id).to eql("rick")
    expect(product.membership_payment_type).to eql("upgrade")
  end

  it "Respects fed defaults" do
    # Pre-fill prompt inputs
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.rewind

    defaults = {value: "1500.01", membership_id: "coolest people club", member_id: "rick rochier", membership_payment_type: "upgrade"}
    product = prompted_payment_factory(Membership, prompt, db, defaults)
    expect(product.value).to eql(1500.01)
    expect(product.membership_id).to eql("coolest people club")
    expect(product.member_id).to eql("rick rochier")
    expect(product.membership_payment_type).to eql("upgrade")
  end
end

describe Video do
  # Setup.  Configure prompt as a test object, rather than a normal prompt
  let(:prompt) {TTY::Prompt::Test.new}
  let(:db) {Database.new}

  it "A valid kwarg set can be collected from a prompt" do
    # Pre-fill prompt inputs
    prompt.input.puts "20"
    prompt.input.puts "harry potter"
    prompt.input.puts "erics house"
    prompt.input.puts ""
    prompt.input.rewind

    kwargs = Video.kwargs_from_prompt(prompt, {})
    expect(kwargs[:value]).to eql(20.0)
    expect(kwargs[:product_id]).to eql("harry potter")
    expect(kwargs[:shipping_address]).to eql("erics house")
    expect(kwargs[:agent]).to be_nil
  end

  it "It can construct a valid object" do
    # Pre-fill prompt inputs
    prompt.input.puts "20"
    prompt.input.puts "harry potter"
    prompt.input.puts "erics house"
    prompt.input.puts "john"
    prompt.input.rewind

    product = prompted_payment_factory(Video, prompt, db)
    expect(product.value).to eql(20.0)
    expect(product.product_id).to eql("harry potter")
    expect(product.shipping_address).to eql("erics house")
    expect(product.agent).to eql("john")
  end

  it "Respects fed defaults" do
    # Pre-fill prompt inputs
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.puts ""
    prompt.input.rewind

    defaults = {value: 37, product_id: "how to ski", shipping_address: "bills house", agent: "bill"}
    product = prompted_payment_factory(Video, prompt, db, defaults)
    expect(product.value).to eql(37.0)
    expect(product.product_id).to eql("how to ski")
    expect(product.shipping_address).to eql("bills house")
    expect(product.agent).to eql("bill")
  end
end