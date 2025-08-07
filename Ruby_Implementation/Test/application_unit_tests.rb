# frozen_string_literal: true

require "tty-prompt"
require "tty/prompt/test"
require 'rspec/autorun'
require '../payment'
require '../database'
require '../application'

# Unfortunately I seem to have to include this or prints after the prompt get printed awkwardly in the middle of the tests
def silence_stream(stream=STDOUT)
  original_stream = stream.dup
  stream.reopen(File.open('/dev/null', 'w'))
  yield
ensure
  stream.reopen(original_stream)
end

describe "obtain_database" do
  # Setup.  Configure prompt as a test object, rather than a normal prompt
  let(:prompt) {TTY::Prompt::Test.new}

  before(:context) do
    # Make sure any database files that will be used are not present, as they could influence many of these tests.it
    # This stuff SHOULD get cleaned up by the after clause, but doing it here just for certainty, in case some other
    # action leaves conflicting files around
    begin
      File.delete("temp_test_db.dat")
    rescue Errno::ENOENT
    end
  end

  after(:example) do
    # Clean up all databases that will be touched by this test.
    begin
      File.delete("temp_test_db.dat")
    rescue Errno::ENOENT
    end
  end

  it "if path is provided and exists it loads the database" do
    db = Database.new()
    db.save("temp_test_db.dat")
    db = nil
    db_path = nil
    expect{db_path, db = obtain_database("temp_test_db.dat", prompt)}.to output(include('Successfully loaded database')).to_stdout
    expect(db_path).to eql("temp_test_db.dat")
    expect(db).to be_an_instance_of(Database)
  end

  it "if path empty it will return a temporary database" do
    db = nil
    db_path = nil
    expect{db_path, db = obtain_database("", prompt)}.to output(include('temporary database will be used')).to_stdout
    expect(db_path).to be_nil
    expect(db).to be_an_instance_of(Database)
  end

  it "will gracefully handle the database not being found and present the menu" do
    prompt.input.puts "3"
    prompt.input.rewind
    db = nil
    db_path = nil
    # We are expecting a system exit here because we are feeding the prompt option 3 (exit).  I don't seem to be
    # able to test that the prompt is fired by looking for an output
    expect{db_path, db = obtain_database("nonexistant.db", prompt)}.to raise_error(SystemExit)
  end

  it "will gracefully handle the database not being found and create a temporary one when asked" do
    prompt.input.puts "2"
    prompt.input.rewind
    db = nil
    db_path = nil
    silence_stream do
      db_path, db = obtain_database("nonexistant.db", prompt)
    end
    expect(db_path).to be_nil
    expect(db).to be_an_instance_of(Database)
  end

  it "will gracefully handle the database not being found and create a new one when asked" do
    prompt.input.puts "1"
    prompt.input.rewind
    db = nil
    db_path = nil
    silence_stream do
      db_path, db = obtain_database("temp_test_db.dat", prompt)
    end
    expect(db_path).to eql("temp_test_db.dat")
    expect(db).to be_an_instance_of(Database)
  end
end