"""
This script exists as an example and for testing purposes.  This is where a database and processor will be
constructed and various payments defined and processed to demonstrate the project.
"""

from database import Database
from processor import Processor
import payment

db = Database()
processor = Processor(db)

payment_list = [
    payment.PhysicalProduct(
        database = db,
        value = 2.50,
        product_id = "apple",
        shipping_address = "erics house",
        agent = "bob"
    ),
    payment.PhysicalProduct(
        database = db,
        value = 2.25,
        product_id = "pear",
        shipping_address = "erics house",
        agent = "bob"
    ),
    payment.PhysicalProduct(
        database = db,
        value = 2000.00,
        product_id = "laptop",
        shipping_address = "erics house",
        agent = "bob"
    ),
    payment.Book(
        database = db,
        value = 150.00,
        product_id = "Jackson EM Textbook",
        shipping_address = "erics house",
        agent = "anne"
    ),
    payment.Membership(
        database = db,
        value = 12.99,
        membership_payment_type = "activation",
        membership_id = "streaming_service",
        member_id = "Jim"
    ),
    payment.Membership(
        database = db,
        value = 34.00,
        membership_payment_type = "upgrade",
        membership_id = "cleaning_service",
        member_id = "Mary"
    ),
    payment.Video(
        database=db,
        value=8.00,
        product_id="Jaws",
        shipping_address="erics house",
        agent="frank"
    ),
payment.Video(
        database=db,
        value=13.00,
        product_id="Learning to Ski",
        shipping_address="erics house",
        agent="frank"
    )
]
failed_payments = processor.process_payments(payment_list)

print("====================================")
print("Completed processing of all payments")
if failed_payments:
    print("The following payments failed processing...")
    try:
        for each in failed_payments:
            print(each)
    except TypeError:
        print(failed_payments)

