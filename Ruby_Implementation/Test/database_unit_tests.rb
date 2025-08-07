# frozen_string_literal: true

require '../database'
require 'rspec/autorun'

describe Database do
  let(:db) { Database.new }

  it 'contains an incrementing counter' do
    id_db = Database.new
    expect(id_db.get_next_id).to eq(0)
    expect(id_db.get_next_id).to eq(1)
    expect(id_db.get_next_id).to eq(2)
  end

  it 'has a price_table' do
    expect(db.price_table['pants']).to eq(45.50)
  end
  it 'price_table is read-only' do
    expect { db.price_table['pants'] = 55.00 }.to raise_error(FrozenError)
  end
  it 'price_table has a default' do
    expect(db.price_table['fake item']).to eq(9.99)
  end

  it 'has a commission_table' do
    expect(db.commission_table['laptop']).to eq(0.05)
  end
  it 'commission_table is read-only' do
    expect { db.commission_table['laptop'] = 0.07 }.to raise_error(FrozenError)
  end
  it 'commission_table has a default' do
    expect(db.commission_table['fake item']).to eq(0.0)
  end

  it 'has a video_addons table' do
    expect(db.video_addons['Learning to Ski']).to eq('First Aid')
  end
  it 'video_addons is read-only' do
    expect { db.video_addons['Learning to Ski'] = 'Ski Harder' }.to raise_error(FrozenError)
  end

  it 'has a read/write processed_payments table' do
    expect { db.processed_payments[0] = 'new order' }.not_to raise_error
    expect(db.processed_payments[0]).to eq('new order')
  end

  it 'has a read-write failed_payments table' do
    expect { db.failed_payments[0] = 'new order' }.not_to raise_error
    expect(db.failed_payments[0]).to eq('new order')
  end

  it 'has a read-write pending_payments table' do
    expect { db.pending_payments[0] = 'new order' }.not_to raise_error
    expect(db.pending_payments[0]).to eq('new order')
  end

  it "can save and load the database to/from a file" do
    test_path = "test_db.dat"

    # Make a new database and set some data, then save it.
    io_db = Database.new()
    io_db.processed_payments["test_data"] = "data"
    io_db.get_next_id()
    io_db.save(test_path)

    # Delete the database
    io_db = nil

    # Reload
    io_db = Database.load(test_path)
    expect(io_db.processed_payments["test_data"]).to eql("data")
    expect(io_db.get_next_id()).to eql(1)
  ensure
    File.delete(test_path)
  end
end
