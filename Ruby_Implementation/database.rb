# Define a database that will hold all manner of common and non-specific needed for payment processing.  This is
# intended to mimic what would in a real system be something more akin to an SQL database.  It should be constructed
# just once for the system.  As this is just a demonstration, it will not have persistence like a real database would.

# Object that represents a fictional ERP SQL database and holds varous bits of common information that will be used by
# the payment processor.  Data are implemented as class attributes.  The database should be considered read only once
# instantiated from the perspective of payments, though the processor will archive payments in the processed_orders
# and failed_orders hash maps.

class ReadonlyHash
    def initialize(h, default=nil)
        h.default = default
        @h = h

    end

    def [](key)
        @h[key]
    end

    def []=(key, value)
        raise FrozenError.new(msg="This object is read only.")
    end
end

class Database
    attr_reader :price_table, :commission_table, :video_addons
    attr_accessor :processed_orders, :failed_orders

    def initialize()
        @price_table = ReadonlyHash.new(
            {
                "pants" => 45.50,
                "apple" => 1.99,
                "laptop" => 1299.00
            },
            default = 9.99
        )

        @commission_table = ReadonlyHash.new(
            {
                "apple" => 0.0,
                "laptop" => 0.05
            },
            default = 0.0
        )

        @video_addons = ReadonlyHash.new(
            {
                "Learning to Ski" => "First Aid"
            }
        )

        @processed_orders = {}
        @failed_orders = {}
        @next_id = -1
    end

    def get_next_id()
        @next_id += 1
    end
end
