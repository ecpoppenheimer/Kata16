# frozen_string_literal: true

require '../processor'
require '../payment'
require '../database'
require 'rspec/autorun'

RSpec.configure do |c|
  c.before { allow($stdout).to receive(:puts) }
end

describe PhysicalProduct do
  it 'Generates a packing slip for a physical product.' do
    db = Database.new
    proc = Processor.new(db)
    payment = PhysicalProduct.new(
      database: db,
      value: 5.0,
      product_id: 'laptop',
      shipping_address: 'my house',
      agent: 'Tom'
    )
    expect { proc.process_payment(payment) }.to output(include('Generate packing slip')).to_stdout
  end

  it 'Generates a commission payment for a physical product that needs one.' do
    db = Database.new
    proc = Processor.new(db)
    payment = PhysicalProduct.new(
      database: db,
      value: 5.0,
      product_id: 'laptop',
      shipping_address: 'my house',
      agent: 'Tom'
    )
    expect { proc.process_payment(payment) }.to output(include('Generate commission')).to_stdout
  end

  it 'Does not generate a commission payment for a product that is set in the database to zero commission.' do
    db = Database.new
    proc = Processor.new(db)
    payment = PhysicalProduct.new(
      database: db,
      value: 5.0,
      product_id: 'apple',
      shipping_address: 'my house',
      agent: 'Tom'
    )
    expect { proc.process_payment(payment) }.to output(include('Checking... no commission due')).to_stdout
  end

  it 'Does not generate a commission payment for a product that is not in the commission database.' do
    db = Database.new
    proc = Processor.new(db)
    payment = PhysicalProduct.new(
      database: db,
      value: 5.0,
      product_id: 'candle',
      shipping_address: 'my house',
      agent: 'Tom'
    )
    expect { proc.process_payment(payment) }.to output(include('Checking... no commission due')).to_stdout
  end

  it 'Does not generate a commission payment it the agent is not specified.' do
    db = Database.new
    proc = Processor.new(db)
    payment = PhysicalProduct.new(
      database: db,
      value: 5.0,
      product_id: 'laptop',
      shipping_address: 'my house',
      agent: nil
    )
    expect { proc.process_payment(payment) }.to output(include('Checking... no commission due')).to_stdout
  end
end

describe Book do
  it 'Generates a royalty payment for a book commission.' do
    db = Database.new
    proc = Processor.new(db)
    payment = Book.new(
      database: db,
      value: 5.0,
      product_id: 'Harry Potter',
      shipping_address: 'my house',
      agent: 'Bill'
    )
    expect { proc.process_payment(payment) }.to output(include('Generate royalty department packing slip')).to_stdout
  end
end

describe Membership do
  it 'Fails if membership_payment_type is invalid' do
    db = Database.new
    Processor.new(db)
    expect do
      Membership.new(
        database: db,
        value: 5.0,
        membership_payment_type: 'neither',
        membership_id: 'Cool People Club',
        member_id: 'Sam'
      )
    end.to raise_error("Invalid argument: membership_payment_type must be either 'upgrade' or 'activation'.")
  end

  it 'Generates an activation email for a membership activation' do
    db = Database.new
    proc = Processor.new(db)
    payment = Membership.new(
      database: db,
      value: 5.0,
      membership_payment_type: 'activation',
      membership_id: 'Cool People Club',
      member_id: 'Sam'
    )
    expect { proc.process_payment(payment) }.to output(include('Send activation email to user')).to_stdout
  end

  it 'Generates a membership activation' do
    db = Database.new
    proc = Processor.new(db)
    payment = Membership.new(
      database: db,
      value: 5.0,
      membership_payment_type: 'activation',
      membership_id: 'Cool People Club',
      member_id: 'Sam'
    )
    expect { proc.process_payment(payment) }.to output(include('Activate membership')).to_stdout
  end

  it 'Generates an upgrade email for a membership upgrade' do
    db = Database.new
    proc = Processor.new(db)
    payment = Membership.new(
      database: db,
      value: 5.0,
      membership_payment_type: 'upgrade',
      membership_id: 'Cool People Club',
      member_id: 'Sam'
    )
    expect { proc.process_payment(payment) }.to output(include('has been upgraded')).to_stdout
  end

  it 'Generates a membership upgrade' do
    db = Database.new
    proc = Processor.new(db)
    payment = Membership.new(
      database: db,
      value: 5.0,
      membership_payment_type: 'upgrade',
      membership_id: 'Cool People Club',
      member_id: 'Sam'
    )
    expect { proc.process_payment(payment) }.to output(include('Upgrade membership of type')).to_stdout
  end
end

describe Video do
  it 'Processes a video' do
    db = Database.new
    proc = Processor.new(db)
    payment = Video.new(
      database: db,
      value: 5.0,
      product_id: 'Cars',
      shipping_address: 'my house',
      agent: nil
    )
    expect { proc.process_payment(payment) }.to output(include('Generate packing slip')).to_stdout
  end

  it "Doesn't include an inappropriate add-on" do
    db = Database.new
    proc = Processor.new(db)
    payment = Video.new(
      database: db,
      value: 5.0,
      product_id: 'Cars',
      shipping_address: 'my house',
      agent: nil
    )
    expect { proc.process_payment(payment) }.to_not output(include('Including add-on to packing slip')).to_stdout
  end

  it 'Includes first aid video for skiing video' do
    db = Database.new
    proc = Processor.new(db)
    payment = Video.new(
      database: db,
      value: 5.0,
      product_id: 'Learning to Ski',
      shipping_address: 'my house',
      agent: nil
    )
    expect { proc.process_payment(payment) }.to output(include('Including add-on to packing slip: First Aid')).to_stdout
  end
end
