"""
Define an object that mimics an ERP system.  The processor will accept a completed payment object and run it,
during the course of which the payment will call various methods on the processor to actually accomplish work.  Since
this is just a demo, the processor will only print statements showing what actions it is taking throughout the course
of processing a payment.

Implement new functions within the processor as necessary to satisfy processing requirements.  Note in the docstring
for each process operation which attributes each operation will need to access, to help determine compatibility.
"""

from payment import Payment

class Processor:
    def __init__(self, database):
        """
        :param database: A reference to the previously created system database.
        """
        self.database = database

    def process_payments(self, arg):
        """
        Process either a single payment, or an iterable of several
        :param arg: Either a single Payment object, or an iterable of such objects
        :return: Either a list of payments that failed, if a list was given, or a single payment that failed,
        if only one was provided.  May be an empty list or none if there were no failures.
        """
        if isinstance(arg, Payment):
            return self.process_payment(arg)
        else:
            failed_orders = []
            for each in arg:
                result = self.process_payment(each)
                if result is not None:
                    failed_orders.append(result)
            return failed_orders

    def process_payment(self, payment):
        """
        Process a single payment
        :param payment: The payment to process
        :return: the payment, if processing failed, or None if it succeeded
        """
        failed_order = None

        print(f"Beginning processing of payment of ${payment.value:.2f} with id# {payment.payment_id}.")
        if payment.payment_id in self.database.processed_orders.keys():
            print()
        try:
            payment.process_begin(self)
            payment.process_middle(self)
            payment.process_end(self)
        except Exception as e:
            failed_order = payment
            self.database.failed_orders[payment.payment_id] = payment
            print(" X Unhandled exception raised during processing!")
            print(f"    > {e}")
            print(f" - Processing aborted!\n")
        else:
            self.database.processed_orders[payment.payment_id] = payment
            self.database.failed_orders.pop(payment.payment_id, None)
            print(f" - Processing completed!\n")


        return failed_order

    def generate_packing_slip(self, payment):
        """
        Generate a packing slip for a payment.

        Requires following payment attributes:
            product_id
            shipping_address
        """
        print(f" | Generate packing slip for product {payment.product_id} to address :{payment.shipping_address}.")

    def generate_commission(self, payment):
        """
        Generate a commission payment for a physical product.  Obtains commission values from
        database.commission_table.

        Requires the following payment attributes:
            value
            product_id
            agent
        """
        commission = round(self.database.commission_table[payment.product_id] * payment.value, 2)
        if commission > 0.0 and payment.agent is not None:
            print(f" | Generate commission for agent {payment.agent} for ${commission:.2f}.")
        else:
            print(f" | Checking... no commission due.")

    def generate_royalty_packing_slip(self, payment):
        """
        Generate a secondary packing slip for a payment that goes to the royalty department.

        Requires following payment attributes:
            product_id
            shipping_address
        """
        print(f" | Generate royalty department packing slip for product {payment.product_id} to address: "
              f"{payment.shipping_address}.")

    def send_membership_email(self, payment):
        """
        Send an email notifying the owner that their membership has been updated

        Requires following payment attributes:
            membership_payment_type
            membership_id
            member_id
        """
        if payment.membership_payment_type == "upgrade":
            print(f" | Send email to user user {payment.member_id} that their {payment.membership_id} has been "
                  f"upgraded.")
        else: # this is for an activation
            print(f" | Send activation email to user user {payment.member_id} for their {payment.membership_id} "
                  f"membership.")

    def upgrade_membership(self, payment):
        """
        Upgrade a membership

        Requires following payment attributes:
            membership_id
            member_id
        """
        print(f" | Upgrade membership of type {payment.membership_id} for user {payment.member_id}.")

    def activate_membership(self, payment):
        """
        Activate a membership

        Requires following payment attributes:
            membership_id
            member_id
        """
        print(f" | Activate membership of type {payment.membership_id} for user {payment.member_id}.")

    def video_addon(self, add_on):
        """
        Include an add-on to a video payment.

        Requires following payment attributes:
            ---
        """
        print(f" | Including add-on to packing slip: {add_on}")


