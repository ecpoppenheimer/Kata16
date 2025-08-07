# frozen_string_literal: true

require '../processor'
require '../payment'
require '../database'
require "tty-prompt"

def obtain_database(db_path, prompt)
  if db_path.nil? or db_path.empty?
    puts "No database path specified, so a temporary database will be used."
    return nil, Database.new()
  else
    begin
      db = Database.load(db_path)
      puts "Successfully loaded database at #{db_path}"
      return db_path, db
    rescue Errno::ENOENT
      case prompt.select("Database not found at path #{db_path}.  Create new?: (1 or 2)") do |menu|
          menu.enum "."
          menu.choice "Create new database", "new"
          menu.choice "Use temporary database", "temp"
          menu.choice "Exit", "exit"
        end
      when "new"
        puts "Creating new database.  File will be saved to path on program exit..."
        begin
          # Attempt to create and save the database, which should validate whether the path is valid.
          db = Database.new()
          db.save(db_path)
          return db_path, db
        rescue
          puts "Unable to write to path #{db_path}.  Exiting."
          exit()
        end
      when "temp"
        puts "Using temporary database.  No data will be persisted once program exits."
        return nil, Database.new()
      when "exit"
        exit()
      end
    end
  end
end

def payment_entry_edit_loop(prompt, db, processor, new_payment, payment_class, default="Process now.")
  while true do
    puts "--------------------------"
    puts "Payment Review:"
    new_payment.pretty_print()
    puts "--------------------------"
    case prompt.select("Action to take with completed payment", default: default) do |menu|
        menu.enum "."
        menu.choice "Process now.", "process"
        menu.choice "Add to pending payments queue.", "queue"
        menu.choice "Edit.", "edit"
        menu.choice "Cancel without saving payment.", "cancel"
      end
    when "process"
      processor.process_payment(new_payment)
      break
    when "queue"
      db.queue_payment(new_payment)
      break
    when "edit"
      new_values = payment_class.kwargs_from_prompt(prompt, {}, new_payment.to_kwargs())
      new_payment.update(**new_values)
    when "cancel"
      break
    end
  end
end

def make_new_payment(prompt, db, processor)
  payment_type = prompt.select("Product type to create:", PaymentClassHash.keys)
  payment_class = PaymentClassHash[payment_type]
  new_payment = prompted_payment_factory(payment_class, prompt, db)

  # Loop that provides the ability to either edit the entry (repeatedly) or process it or queue it.
  payment_entry_edit_loop(prompt, db, processor, new_payment, payment_class)
end

def process_pending_payments(db, processor)
  processor.process_pending()
end

def view_payments_in_db(prompt, db)
  case prompt.select("Which catagory to view?") do |menu|
      menu.enum "."
      menu.choice "Successfully processed payments.", "processed"
      menu.choice "Payments that failed processing.", "failed"
      menu.choice "Payments queued for processing.", "queued"
      menu.choice "Back to main menu.", "Back"
    end
  when "processed"
    puts "Processed Payments:"
    db.processed_payments.each do |id, payment|
      payment.pretty_print
    end
    puts "-------------------"
  when "failed"
    puts "Failed  Payments:"
    db.failed_payments.each do |id, payment|
      payment.pretty_print
    end
    puts "-------------------"
  when "queued"
    puts "Queued Payments:"
    db.pending_payments.each do |id, payment|
      payment.pretty_print
    end
    puts "-------------------"
  when "back"
  end
end

def attempt_fix_failed_payment(prompt, db, processor)
  if db.failed_payments.empty?
    puts "No failed payments to fix."
  else
    # Make the choices fed to the prompt selector.  Keys are short semi-descriptive names of each payment and the value
    # returned from the prompt will be the payment_id of the selected payment.
    selection_choices = {}
    db.failed_payments.each do |id, payment|
      selection_choices["#{id}: #{payment.class} for $#{payment.value}"] = id
    end
    selection_choices["Go Back"] = -1
    selected_id = prompt.select("Choose which payment to fix.", selection_choices, convert: :int)
    if selected_id == -1
      return
    end

    # I need to be careful that I not allow duplication of payment entries.  After consideration, I've decided to
    # delegate this to the database/processor.  There are three ways the edit loop can be ended: processing, queueing,
    # or canceling.  If the loop is canceled, then the payment should continue to be considered failing and so nothing
    # needs to change.  If it is either processed or queued, both of these operations will automatically remove it
    # from the failed_payments table.
    # There is one other way for the loop to end, which is if it throws an exception.  Do I need to handle this?
    # After thinking about it, I think I am ok not handling an exception from the loop.  If the exception occurs
    # anywhere other than during processing or queueing, the default behavior will be to leave the payment in the
    # failure table, which seems like the correct thing to do with it.  The processor should already handle errors
    # during processing, so I don't think I have to worry about that.  This leaves just the queuer as a possible source
    # of an unexpected error, but that function seems too simple to throw an unexpected error, so I think I can safely
    # not worry about this.  As a last-ditch safety, the processor should refuse to do anything with a payment if it has
    # already been processed, and will NOT add it to the failure table - it will just ignore the request.  This seems
    # more correct to me than any other option, as processing is the critical operation that must avoid duplication.
    selected_payment = db.failed_payments[selected_id]
    payment_entry_edit_loop(prompt, db, processor, selected_payment, selected_payment.class, default="Edit.")
  end
end

def main_loop(prompt, db, processor)
  case prompt.select("Which action would you like to take?") do |menu|
      menu.enum "."
      menu.choice "Enter a new payment", "new"
      menu.choice "Process all pending payments", "process"
      menu.choice "View payments", "view"
      menu.choice "Fix a failed payment", "fix"
      menu.choice "Exit", "exit"
    end
  when "new"
    make_new_payment(prompt, db, processor)
    return true
  when "process"
    process_pending_payments(db, processor)
    return true
  when "view"
    view_payments_in_db(prompt, db)
    return true
  when "fix"
    attempt_fix_failed_payment(prompt, db, processor)
    return true
  when "exit"
    return false
  end
end

def main(path_arg, prompt)
  db_path, db = obtain_database(path_arg, prompt)
  processor = Processor.new(db)

  # For a while I thought I wanted the ability to press escape to break out of the program immediately, which can
  # be accomplished with the following bit of code, which causes the prompt to throw an interrupt exception on pressing
  # escape.  Having finished the menu I no longer feel this is necessary, but wanted to store this here nonetheless.
  # prompt.on(:keyescape) do |event|
  #   raise Interrupt.new()
  # end

  # If we get here, db_path will either be a valid file name or nil, and db will be a working database
  while main_loop(prompt, db, processor) do
  end

  # if db_path is not nil, save the database.  Path should have already been validated by obtain_database
  if db_path
    begin
      db.save(db_path)
      puts "Successfully saved database and exiting."
    rescue => e
      puts "Error saving database: "
      puts e.message
      puts "Exiting without saving."
    end
  end
end

if __FILE__ == $0
  prompt = TTY::Prompt.new()
  main(ARGV[0], prompt)
end
