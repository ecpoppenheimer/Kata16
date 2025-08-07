# frozen_string_literal: true

require '../payment'
require '../database'
require 'rspec/autorun'

describe Payment do
  let(:db) { Database.new }

  it 'grabs an ID from the database on initialization' do
    id = db.get_next_id
    p = Payment.new(database: db, value: 5.00)
    expect(p.payment_id).to eq(id + 1)
  end
  it 'has an attributes set' do
    expect(Payment.attributes).to be_a(Set)
  end
  it 'attributes is read-only' do
    expect { Payment.attributes << 'foo' }.to raise_error(FrozenError)
  end

  it 'has an required_kwargs set' do
    expect(Payment.required_kwargs).to be_a(Set)
  end
  it 'required_kwargs is read-only' do
    expect { Payment.required_kwargs << 'foo' }.to raise_error(FrozenError)
  end

  it 'has an filled_kwargs set' do
    expect(Payment.filled_kwargs).to be_a(Set)
  end
  it 'filled_kwargs is read-only' do
    expect { Payment.filled_kwargs << 'foo' }.to raise_error(FrozenError)
  end
end
