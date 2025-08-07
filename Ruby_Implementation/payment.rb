# frozen_string_literal: true

require 'set'

class Payment
  @attributes = Set['database', 'attributes', 'required_kwargs', 'filled_kwargs', 'value', 'payment_id'].freeze
  class << self
    attr_reader :attributes
  end
  @required_kwargs = Set['database', 'value'].freeze
  class << self
    attr_reader :required_kwargs
  end
  @filled_kwargs = Set[].freeze
  class << self
    attr_reader :filled_kwargs
  end

  attr_reader :database, :value, :payment_id

  def initialize(**kwargs)
    @database = kwargs[:database]
    @value = kwargs[:value]
    @payment_id = database.get_next_id()
  end

  def update(**kwargs)
    @value = kwargs[:value]
  end

  def to_s()
    return "Payment ##{@payment_id} for $#{@value}"
  end

  def pretty_print()
    puts "Payment ##{@payment_id}"
    puts " | Value: #{@value}"
  end

  def to_kwargs()
    return {
      value: @value
    }
  end

  def process_begin(processor); end

  def process_middle(processor); end

  def process_end(processor); end

  def self.kwargs_from_prompt(prompt, kwargs, defaults={})
    # Accumulate a kwargs hash with values from a user prompt.  The kwargs hash fed to this function will be returned
    # with the necessary kwargs to instantiate this object (at this level of inheritance).
    defaults = {value: 5.0}.merge(defaults)
    kwargs[:value] = prompt.ask("Payment value (must be a number >= 0):", convert: :float, default: defaults[:value]) do |q|
      q.convert :float
      q.messages[:valid?] = "Invalid: Must be a number >= 0"
      q.validate do |input|
        Float(input) >= 0
      end
    end
    return kwargs
  end
end

def prompted_payment_factory(cls, prompt, database, defaults={})
  kwargs = cls.kwargs_from_prompt(prompt, {}, defaults)
  kwargs[:database] = database
  return cls.new(**kwargs)
end

def helper_check_required_kwargs(cls)
  # Helper function that prints out all kwargs that will be required for the constructor of the class you give it to
  # check.  This function also checks for conflicts where a single kwarg is used by more than one parent class,
  # which may lead to unexpected behavior and should be avoided.
  #
  # :param cls: The class (must be a subclass of Payment, conforming to the style guide) you want to check.
  all_kwargs = {}
  removed_kwargs = Set.new

  # all_kwargs is a hash that maps kwargs to set of classes that require them.
  # Need to slice off Ruby generic classes, which we do not care about for this function.
  for c in cls.ancestors[..-4] do
    for required_kwarg in c.required_kwargs.each do
      if all_kwargs.keys.include? required_kwarg
        all_kwargs[required_kwarg] << c.name
      else
        all_kwargs[required_kwarg] = Set[c.name]
      end
    end

    # removed kwargs is a set of all kwargs that get filled by any class in the hierarchy and so are unneeded.
    removed_kwargs |= c.filled_kwargs
  end

  puts format('Checking required kwargs for class %s...', cls)

  all_kwargs.each do |kwarg, classes|
    if classes.length == 1
      # Don't want to print anything of the kwarg is unique and not removed.
      puts " | kwarg #{kwarg} used by class #{classes.to_a.join(', ')}" unless removed_kwargs.include?(kwarg)
    else
      # Whether or not the kwargs is filled anywhere, if it is not unique we need to know.
      puts " X CONFLICT WARNING: kwarg #{kwarg} used by multiple classes: #{classes.to_a.join(', ')}"
    end
  end
  puts ' - Check complete.'
  puts "------------------\n"
end

def helper_check_declared_attributes(cls)
  # Helper function that prints out all attributes of parent classes of the class you are checking.  This helps
  # ensure that you are not overriding any parent class attributes, which is considered illegal by this project's
  # style guide.  Prints a warning if any conflicts are discovered.
  #
  # :param cls: The class (must be a subclass of Payment, conforming to the style guide) you want to check.
  all_attributes = {}

  # Ignore the last object in the MRO, which is object and so does not have 'attributes'
  for c in cls.ancestors[..-4] do
    for attr in c.attributes.each do
      if all_attributes.keys.include? attr
        all_attributes[attr] << c.name
      else
        all_attributes[attr] = Set[c.name]
      end
    end
  end

  puts format('Compiling parent attributes for class %s...', cls)
  all_attributes.each do |attr, classes|
    if classes.length == 1
      puts " | attribute #{attr} used by class #{classes.to_a.join(' ,')}"
    else
      puts " X CONFLICT WARNING: attribute #{attr} used by multiple classes: #{classes.to_a.join(', ')}"
    end
  end
  puts ' - Check complete.'
  puts "------------------\n"
end

# ======================================================================================================================
# Payment subclass implementations below this line
# ======================================================================================================================

class PhysicalProduct < Payment
  @attributes = Set['product_id', 'shipping_address', 'agent'].freeze
  class << self
    attr_reader :attributes
  end
  @required_kwargs = Set['product_id', 'shipping_address', 'agent'].freeze
  class << self
    attr_reader :required_kwargs
  end
  @filled_kwargs = Set[].freeze
  class << self
    attr_reader :filled_kwargs
  end

  attr_reader :product_id, :shipping_address, :agent

  def initialize(**kwargs)
    # Required kwargs:
    # database
    # value
    # product_id
    # shipping_address
    # agent
    super
    @product_id = kwargs[:product_id]
    @shipping_address = kwargs[:shipping_address]
    @agent = kwargs[:agent]
  end

  def update(**kwargs)
    super
    @product_id = kwargs[:product_id]
    @shipping_address = kwargs[:shipping_address]
    @agent = kwargs[:agent]
  end

  def to_s()
    return "Physical Product ##{@payment_id} of #{product_id} for $#{@value}"
  end

  def pretty_print()
    puts "Physical Product ##{@payment_id}"
    puts " | Value: #{@value}"
    puts " | Product ID: #{@product_id}"
    puts " | Shipping Address: #{@shipping_address}"
    puts " | Agent: #{@agent}"
  end

  def to_kwargs()
    return super.merge({
      product_id: @product_id,
      shipping_address: @shipping_address,
      agent: @agent || ""
    })
  end

  def process_middle(processor)
    super
    processor.generate_commission(self)
  end

  def process_end(processor)
    processor.generate_packing_slip(self)
    super
  end

  def self.kwargs_from_prompt(prompt, kwargs, defaults={})
    # Accumulate a kwargs hash suitable to instantiate this object via user prompt.
    kwargs = super(prompt, kwargs, defaults)
    defaults = {product_id: "laptop", shipping_address: "my_house", agent: ""}.merge(defaults)
    kwargs[:product_id] = prompt.ask("Product ID (string identifying product):", default: defaults[:product_id], required: true)
    kwargs[:shipping_address] = prompt.ask("Shipping Address (string):", default: defaults[:shipping_address], required: true)
    agent = prompt.ask("Sales Agent Name (string, leave blank for none):", default: defaults[:agent])
    kwargs[:agent] = agent.strip.empty? ? nil : agent
    return kwargs
  end
end

class Book < PhysicalProduct
  # Required kwargs:
  # database
  # value
  # product_id
  # shipping_address
  # agent
  @attributes = Set[].freeze
  class << self
    attr_reader :attributes
  end
  @required_kwargs = Set[].freeze
  class << self
    attr_reader :required_kwargs
  end
  @filled_kwargs = Set[].freeze
  class << self
    attr_reader :filled_kwargs
  end

  def to_s()
    return "Book ##{@payment_id} of #{product_id} for $#{@value}"
  end

  def pretty_print()
    puts "Book ##{@payment_id}"
    puts " | Value: #{@value}"
    puts " | Product ID: #{@product_id}"
    puts " | Shipping Address: #{@shipping_address}"
    puts " | Agent: #{@agent}"
  end

  def process_middle(processor)
    super
    processor.generate_royalty_packing_slip(self)
  end
end

class Membership < Payment
  @attributes = Set['membership_payment_type', 'membership_id', 'member_id'].freeze
  class << self
    attr_reader :attributes
  end
  @required_kwargs = Set['membership_payment_type', 'membership_id', 'member_id'].freeze
  class << self
    attr_reader :required_kwargs
  end
  @filled_kwargs = Set[].freeze
  class << self
    attr_reader :filled_kwargs
  end

  attr_reader :membership_payment_type, :membership_id, :member_id

  def initialize(**kwargs)
    # Required kwargs:
    # database
    # value
    # membership_payment_type
    # membership_id
    # member_id

    # Call parent constructor
    super

    # Instantiate attributes
    @membership_id = kwargs[:membership_id]
    @member_id = kwargs[:member_id]
    ptype = kwargs[:membership_payment_type]
    unless %w[upgrade activation].include?(ptype)
      raise ArgumentError.new("Invalid argument: membership_payment_type must be either 'upgrade' or 'activation'.")
    end

    @membership_payment_type = ptype
  end

  def update(**kwargs)
    super
    # Instantiate attributes
    @membership_id = kwargs[:membership_id]
    @member_id = kwargs[:member_id]
    ptype = kwargs[:membership_payment_type]
    unless %w[upgrade activation].include?(ptype)
      raise ArgumentError.new("Invalid argument: membership_payment_type must be either 'upgrade' or 'activation'.")
    end
    @membership_payment_type = ptype
  end

  def to_s()
    return "Membership ##{@payment_id} of #{membership_id} for $#{@value}"
  end

  def pretty_print()
    puts "Membership ##{@payment_id}"
    puts " | Value: #{@value}"
    puts " | Membership ID: #{@membership_id}"
    puts " | Member ID: #{@member_id}"
    puts " | Payment Type: #{@membership_payment_type}"
  end

  def to_kwargs()
    return super.merge({
      membership_id: @membership_id,
      member_id: @member_id,
      membership_payment_type: @membership_payment_type
    })
  end

  def process_middle(processor)
    super

    if @membership_payment_type == 'upgrade'
      processor.upgrade_membership(self)
    else
      processor.activate_membership(self)
    end
  end

  def process_end(processor)
    processor.send_membership_email(self)
    super
  end

  def self.kwargs_from_prompt(prompt, kwargs, defaults={})
    # Accumulate a kwargs hash suitable to instantiate this object via user prompt.
    kwargs = super(prompt, kwargs, defaults)
    defaults = {membership_id: "VIP Club", member_id: "Bob", membership_payment_type: "activation"}.merge(defaults)
    kwargs[:membership_id] = prompt.ask("Membership ID (string identifying membership):", default: defaults[:membership_id], required: true)
    kwargs[:member_id] = prompt.ask("Member ID (string, member's name):", default: defaults[:member_id], required: true)
    kwargs[:membership_payment_type] = prompt.select("Membership payment type: (1 or 2)", default: defaults[:membership_payment_type]) do |menu|
      menu.enum "."
      menu.choice "activation", "activation"
      menu.choice "upgrade", "upgrade"
    end
    return kwargs
  end
end

class Video < PhysicalProduct
  # Required kwargs:
  # database
  # value
  # product_id
  # shipping_address
  # agent
  @attributes = Set[].freeze
  class << self
    attr_reader :attributes
  end
  @required_kwargs = Set[].freeze
  class << self
    attr_reader :required_kwargs
  end
  @filled_kwargs = Set[].freeze
  class << self
    attr_reader :filled_kwargs
  end

  def to_s()
    return "Video ##{@payment_id} of #{product_id} for $#{@value}"
  end

  def pretty_print()
    puts "Video ##{@payment_id}"
    puts " | Value: #{@value}"
    puts " | Product ID: #{@product_id}"
    puts " | Shipping Address: #{@shipping_address}"
    puts " | Agent: #{@agent}"
  end

  def process_middle(processor)
    super

    # Check whether an add-on product is required
    return unless @database.video_addons.has_key? @product_id

    processor.video_addon(@database.video_addons[@product_id])
  end
end

class FailingPayment < Payment
  def process_middle(processor)
    super
    unless @value == 69.0
      raise RuntimeError.new("Forced failure.")
    end
  end
end

PaymentClassHash = {
  "Payment": Payment,
  "Physical Product": PhysicalProduct,
  "Membership": Membership,
  "Book": Book,
  "Video": Video,
  "FailingPayment": FailingPayment
}
