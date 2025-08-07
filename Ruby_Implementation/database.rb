# frozen_string_literal: true

# Define a database that will hold all manner of common and non-specific needed for payment processing.  This is
# intended to mimic what would in a real system be something more akin to an SQL database.  It should be constructed
# just once for the system.  As this is just a demonstration, it will not have persistence like a real database would.

# Object that represents a fictional ERP SQL database and holds varous bits of common information that will be used by
# the payment processor.  Data are implemented as class attributes.  The database should be considered read only once
# instantiated from the perspective of payments, though the processor will archive payments in the processed_orders
# and failed_orders hash maps.

class ReadonlyHash
  # A wrapper for a hash table that makes adding a default value slightly easier, and also prevents reading.  This is
  # Intended to mock a database with fields that should not be modified by this code.
  def initialize(hash, default = nil)
    hash.default = default
    @hash = hash
  end

  def [](key)
    @hash[key]
  end

  def []=(_key, _value)
    raise FrozenError.new('This object is read only.')
  end

  def method_missing(m, *args, &block)
    @hash.send(m, *args, &block)
  end
end

class Database
  # A database with multiple sub-fields.  Intended to mock what would be an ERP database in a fully developed system.
  attr_reader :price_table, :commission_table, :video_addons
  attr_accessor :processed_payments, :failed_payments, :pending_payments

  def initialize
    @price_table = ReadonlyHash.new(
      {
        'pants' => 45.50,
        'apple' => 1.99,
        'laptop' => 1299.00
      },
      9.99
    )

    @commission_table = ReadonlyHash.new(
      {
        'apple' => 0.0,
        'laptop' => 0.05
      },
      0.0
    )

    @video_addons = ReadonlyHash.new(
      {
        'Learning to Ski' => 'First Aid'
      }
    )

    @processed_payments = {}
    @failed_payments = {}
    @pending_payments = {}
    @next_id = -1
  end

  def get_next_id
    @next_id += 1
  end

  def save(path)
    File.open(path, "wb") do |file|
      Marshal.dump(self, file)
    end
  end

  def self.load(path)
    return File.open(path, "rb") do |file|
      Marshal.load(file)
    end
  end

  def queue_payment(payment)
    @pending_payments[payment.payment_id] = payment
    @failed_payments.delete(payment.payment_id)
  end
end
