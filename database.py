"""
Define a database that will hold all manner of common and non-specific needed for payment processing.  This is
intended to mimic what would in a real system be something more akin to an SQL database.  It should be constructed
just once for the system.  As this is just a demonstration, it will not have persistence like a real database would.
"""

from collections import defaultdict

class Database:
    """
    Object that mocks an ERP SQL database and holds varous bits of common information that will be used by the
    payment processor.  Data are implemented as class attributes / methods as this is intended to be a
    singleton. The database should be considered read only once instantiated from the perspective of payments,
    though the processor will archive payments in the processed_orders and failed_orders dictionaries.
    """
    price_table = defaultdict(
        lambda: 9.99,
        {
            "pants": 45.50,
            "apple": 1.99,
            "laptop": 1299.00
        }
    )
    commission_table = defaultdict(
        lambda: .1,
        {
            "apple": 0.0,
            "laptop": 0.05
        }
    )
    video_addons = {
        "Learning to Ski": "First Aid"
    }
    processed_orders = {}
    failed_orders = {}
    _next_id = -1

    @classmethod
    def get_next_id(cls):
        cls._next_id += 1
        return cls._next_id
