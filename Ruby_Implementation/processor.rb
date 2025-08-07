# Define an object that mimics an ERP system.  The processor will accept a completed payment object and run it,
# during the course of which the payment will call various methods on the processor to actually accomplish work.  Since
# this is just a demo, the processor will only print statements showing what actions it is taking throughout the course
# of processing a payment.

# Implement new functions within the processor as necessary to satisfy processing requirements.  Note in the docstring
# for each process operation which attributes each operation will need to access, to help determine compatibility.

require '../payment'

class Processor
  def initialize(database)
    # :param database: A reference to the previously created system database.
    @database = database
  end

  def process_payments(*arg)
    # Process either a single payment, or an iterable of several
    # :param arg: Either a single Payment object, or an iterable of such objects
    # :return: Either a list of payments that failed, if a list was given, or a single payment that failed,
    # if only one was provided.  May be an empty list or none if there were no failures.

    failed_payments = []
    for each in arg
      if each.respond_to?(:each)
        failed_payments += process_payments(*each)
      else
        result = process_payment(each)
        failed_payments << result unless result.nil?
      end
    end
    failed_payments
  end

  def process_payment(payment)
    # Process a single payment
    # :param payment: The payment to process
    # :return: the payment, if processing failed, or None if it succeeded
    failed_order = nil
    puts format('Beginning processing of payment of %0.2f with id #%d.', payment.value, payment.payment_id)

    if @database.processed_payments.keys.include? payment.payment_id
      puts 'Processor received payment with duplicate ID - Not allowed.  This will be ignored but should be considered an error'
      # This is a possibly dangerous (if this were a real payment system) situation.failed_payments.  Determining the
      # correct thing to do in this circumstance is a little difficult.  A real system absolutely needs to not double-
      # process a duplicated payment, but I also want this system to be robust against errors and to not sacrifice
      # itself, as it is expected to be a critical component of business infrastructure which should not so easily
      # be brought down by a simple mistake.  I think the most correct action to take in this case is to not throw an
      # error or break anything, not process the duplicated payment, warn the user, delete the payment from the
      # failed_payments table just in case that is where the duplication occurred, and also to log/report that this
      # occurred in a way that will and initiate a manual audit of the mistake by an administrator.  I am not going to
      # implement that last part as this is just a demonstration and such consequence is out of scope for the project.
      @database.failed_payments.delete(payment.payment_id)
    else
      begin
        payment.process_begin(self)
        payment.process_middle(self)
        payment.process_end(self)
      rescue Exception => e
        failed_order = payment
        @database.failed_payments[payment.payment_id] = payment
        puts ' X Unhandled exception raised during processing!'
        puts "    > #{e}"
        puts " - Processing aborted!\n"
      else
        @database.processed_payments[payment.payment_id] = payment
        @database.failed_payments.delete(payment.payment_id) # Delete the payment from failed_payments if it did not fail.
        puts " - Processing completed!\n"
      end
    end
    failed_order
  end

  def process_pending()
    process_payments(@database.pending_payments.values)
    @database.pending_payments = {}
  end

  def generate_packing_slip(payment)
    # Generate a packing slip for a payment.
    #
    # Requires following payment attributes:
    #     product_id
    #     shipping_address
    puts " | Generate packing slip for product #{payment.product_id} to address: #{payment.shipping_address}."
  end

  def generate_commission(payment)
    # Generate a commission payment for a physical product.  Obtains commission values from
    # database.commission_table.
    #
    # Requires the following payment attributes:
    #     value
    #     product_id
    #     agent
    commission = (@database.commission_table[payment.product_id] * payment.value).round(2)
    if commission > 0.0 and !payment.agent.nil?
      puts format(" | Generate commission for agent #{payment.agent} for %0.2f.", commission)
    else
      puts ' | Checking... no commission due.'
    end
  end

  def generate_royalty_packing_slip(payment)
    # Generate a secondary packing slip for a payment that goes to the royalty department.
    #
    # Requires following payment attributes:
    #     product_id
    #     shipping_address
    puts " | Generate royalty department packing slip for product #{payment.product_id} to address: \
      #{payment.shipping_address}."
  end

  def send_membership_email(payment)
    # Send an email notifying the owner that their membership has been updated
    #
    # Requires following payment attributes:
    #     membership_payment_type
    #     membership_id
    #     member_id
    if payment.membership_payment_type == 'upgrade'
      puts " | Send email to user #{payment.member_id} that their #{payment.membership_id} has been upgraded."
    else # this is for an activation
      puts " | Send activation email to user #{payment.member_id} for their #{payment.membership_id} membership."
    end
  end

  def upgrade_membership(payment)
    # Upgrade a membership
    #
    # Requires following payment attributes:
    #     membership_id
    #     member_id
    puts " | Upgrade membership of type #{payment.membership_id} for user #{payment.member_id}."
  end

  def activate_membership(payment)
    # Activate a membership
    #
    # Requires following payment attributes:
    #     membership_id
    #     member_id
    puts " | Activate membership of type #{payment.membership_id} for user #{payment.member_id}."
  end

  def video_addon(add_on)
    # Include an add-on to a video payment.
    #
    # Requires following payment attributes:
    #     ---
    puts " | Including add-on to packing slip: #{add_on}"
  end
end
