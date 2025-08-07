# frozen_string_literal: true

require '../processor'
require '../payment'
require '../database'
require 'rspec/autorun'

RSpec.configure do |c|
  c.before { allow($stdout).to receive(:puts) }
end

class FailingPayment < Payment
  def process_middle(_processor)
    raise 'FailingPayment Error'
  end
end

describe Processor do
  it 'can process one payment and add it to the database' do
    db = Database.new
    proc = Processor.new(db)
    expect do
      proc.process_payment(Payment.new(database: db, value: 7.0))
    end.to_not raise_error
    expect(db.failed_payments.length).to eql(0)
    expect(db.processed_payments.length).to eql(1)
  end

  it 'a single failed payment does not throw an exception, but prints an error' do
    db = Database.new
    proc = Processor.new(db)
    expect do
      proc.process_payment(FailingPayment.new(database: db, value: 5.0))
    end.to output(include('FailingPayment Error')).to_stdout
  end

  it 'a single failed payment is returned and added to the database failed_payments' do
    db = Database.new
    proc = Processor.new(db)
    output = proc.process_payment(FailingPayment.new(database: db, value: 5.0))
    expect(db.failed_payments.length).to eql(1)
    expect(db.processed_payments.length).to eql(0)
    expect(output).to_not be_nil
  end

  it 'can process one payment if process_payments is called' do
    db = Database.new
    proc = Processor.new(db)
    expect do
      proc.process_payments(Payment.new(database: db, value: 7.0))
    end.to_not raise_error
  end

  it 'can accept multiple payments and add them to the database' do
    db = Database.new
    proc = Processor.new(db)
    expect do
      proc.process_payments(
        Payment.new(database: db, value: 7.0),
        Payment.new(database: db, value: 9.0),
        Payment.new(database: db, value: 10.0)
      )
    end.to_not raise_error
    expect(db.failed_payments.length).to eql(0)
    expect(db.processed_payments.length).to eql(3)
  end

  it 'can accept an iterable of payments and add them to the database' do
    db = Database.new
    proc = Processor.new(db)
    expect do
      proc.process_payments(
        [
          Payment.new(database: db, value: 7.0),
          Payment.new(database: db, value: 9.0),
          Payment.new(database: db, value: 10.0)
        ]
      )
    end.to_not raise_error
    expect(db.failed_payments.length).to eql(0)
    expect(db.processed_payments.length).to eql(3)
  end

  it 'a single failed payment among several will not crash/throw an exception, and the others will still get processed' do
    db = Database.new
    proc = Processor.new(db)
    expect do
      proc.process_payments(
        [
          Payment.new(database: db, value: 7.0),
          FailingPayment.new(database: db, value: 9.0),
          Payment.new(database: db, value: 10.0)
        ]
      )
    end.to_not raise_error
    expect(db.failed_payments.length).to eql(1)
    expect(db.processed_payments.length).to eql(2)
  end

  it 'failed payments will get returned' do
    db = Database.new
    proc = Processor.new(db)
    outputs = proc.process_payments(
      [
        Payment.new(database: db, value: 7.0),
        FailingPayment.new(database: db, value: 9.0),
        Payment.new(database: db, value: 10.0)
      ]
    )
    expect(outputs.length).to eql(1)
  end
end
