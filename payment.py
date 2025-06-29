"""
This file implements a base class for all payments, and will also be where all derived payment types will be
implemented.  Since I expect most payments to be built out of a reasonably deep series of inherited classes and the
goal of this challenge is to make a system that is easily maintainable and expandable, I will implement several
utilities to help elucidate which kinds of data each object requires to function.

 *** Importantly ***

I am specifying a clear style that must be adhered to in all derived payments, to ensure that the system of
derived classes is easy to expand and maintain while functioning correctly and consistently.  Please adhere to
this style guide at all times.  I hope we will encounter no rules that require this, but if you encounter a rule so
complicated or inter-dependant that it cannot be implemented within this stylistic framework, you will likely need
to largely or completely abandon inheritance and code up that particular payment as a singular independent whole.
After this description of rules is an example payment subclass that can be copy-pasted and edited each time a new
payment subclass is made.

Guidelines for making a new payment type subclass:
--------------------------------------------------

1. Create a class that inherits from one or more subclasses of Payment.  If you receive the 'TypeError: cannot create a
consistent method resolution order (MRO)', try re-ordering the classes you are subclassing.
2. In a test environment, call the function 'helper_check_required_kwargs' on your new class.  This function will
check the parent classes and collect all kwargs that must be provided for any of the parent classes and so must be
either specified as arguments to the derived class's constructor or filled during runtime of the constructor.  This
function is provided as a helper for writing the documentation for your derived class and understanding parent
classes' requirements, but should not typically be used in the production system.
3. In a test environment, call the function "helper_check_declared_attributes" to get a list of all attributes
declared by all parent classes of your new class.  This function, similar to above, is provided as a helper to avoid
overloading or overwriting any parent classes attributes.  NO PAYMENT SHOULD EVER OVERWRITE ANY PARENT CLASS ATTRIBUTE.
4. The constructor of your subclass must follow these steps/requirements in order:
    4.a The constructor for your subclass MUST FOLLOW the __init__(self, **kwargs) PATTERN.  Positional arguments are
    not allowed for any Payment subclass.
    4.b You may use kwargs.update() to fill kwargs that will go to parent class initializers, if your derived class is
    able to fill any.  Keep in mind that a reference to the database is always available in kwargs, as it is required
    for the base class.
    4.c You MUST use super().__init__(**kwargs)
    4.d You may then instantiate any attributes for your derived class.  These MAY NOT override any attributes of any
    parent class.
    4.e You should avoid doing anything else in the constructor, and may not call any processing operations here.
5. Define three class attributes for your derived class: attributes, required_kwargs, and filled_kwargs.  These are each
sets of strings and are required for the helper functions to work.  These sets MUST ALWAYS BE DEFINED, even if they
are empty.  These attributes have no function within the production system, but are used solely during development by
the helper functions.
    5.a attributes should hold the name of each attribute defined by your derived class.
    5.b required_kwargs should hold the name of each kwarg that your derived class will expect to be fed to its
    constructor.  This should contain only kwargs defined in the derived_class - kwargs required by parent classes will
    be declared by those classes.
    5.c filled_kwargs should hold the name of any kwarg of any parent class that you are filling via step 4.b in your
    derived class.  These kwargs will not need to be fed to the constructor of the derived class or any future
    children.  kwargs that are being optionally filled but may still be valid inputs to the constructor SHOULD NOT be
    included here, as they are still valid constructor arguments.  This attribute exists to power the helper function to
    help determine which kwargs need to be supplied to their constructor, alongside required_kwargs,
    and this particular attribute merely exists to subtract away required kwargs for parents to the derived class
    that the derived class will handle.
6. Define all necessary process functions: process_begin, process_middle, and process_end.  These functions may
take only a single argument, processor, a reference to the payment system processor.  Most processing steps should
be done in process_middle, particularly those that are not order-dependent with other steps.  process_begin and
process_end are provided in case certain process steps need to reliably be performed before or after others across
different levels of the inheritance hierarchy.  I expect them to be rarely needed, and try as a design pattern to
avoid allowing order of process operations to matter.  If your implementation absolutely requires a specific order of
process step across the inheritance hierarchy more complicated than this, and they do not occur in the correct order
based on the hierarchy MRO, you may need to abandon sub-classing and re-implement the logic of the payment subclass
from a more primitive starting point.  You do not need to implement all three of process_begin, process_middle,
and process_end, though at least one should be implemented to have any purpose to the payment subclass.
    6.a When overriding process_begin or process_middle, the first line of the function implementation must call the
    parent's method: super().process_begin(processor) or super().process_middle(processor).  I.E. parent classes will
    trigger their process operations before those of the derived class.
    6.b When overriding process_end, the last line of the function implementation must call the parent's method:
    super().process_end(processor).  I.E. parent classes will trigger their process end operations after those of the
    derived class.

class ExamplePayment(Payment):
    attributes = set()
    required_kwargs = set()
    filled_kwargs = set()

    def __init__(self, **kwargs):
        # Update / fill kwargs
        db = kwargs["database"]
        kwargs.update({fillable_arg = "foo"})

        # Call parent constructor
        super().__init__(**kwargs)

        # Instantiate local attributes

    def process_begin(self, processor):
        super().process_begin(processor)

        # Code goes here

    def process_middle(self, processor):
        super().process_middle(processor)

        # Code goes here

    def process_end(self, processor):
        # Code goes here

        super().process_end(processor)

"""

class Payment:
    attributes = {"database", "attributes", "required_kwargs", "filled_kwargs", "value", "payment_id"}
    required_kwargs = {"database", "value"}
    filled_kwargs = set()

    def __init__(self, **kwargs):
        self.database = kwargs["database"]
        self.value = kwargs["value"]
        self.payment_id = self.database.get_next_id()

    def process_begin(self, processor):
        pass

    def process_middle(self, processor):
        pass

    def process_end(self, processor):
        pass

def helper_check_required_kwargs(cls):
    """
    Helper function that prints out all kwargs that will be required for the constructor of the class you give it to
    check.  This function also checks for conflicts where a single kwarg is used by more than one parent class,
    which may lead to unexpected behavior and should be avoided.

    :param cls: The class (must be a subclass of Payment, conforming to the style guide) you want to check.
    """
    all_kwargs = {}
    removed_kwargs = set()

    # all_kwargs is a dictionary that maps kwargs to set of classes that require them.
    # Ignore the last object in the MRO, which is object and so does not have 'attributes'
    for c in cls.mro()[:-1]:
        for required_kwarg in c.required_kwargs:
            if required_kwarg in all_kwargs.keys():
                all_kwargs[required_kwarg].add(c.__name__)
            else:
                all_kwargs[required_kwarg] = {c.__name__}

        # removed kwargs is a set of all kwargs that get filled by any class in the hierarchy and so are unneeded.
        removed_kwargs |= c.filled_kwargs

    print(f"Checking required kwargs for class {cls}...")
    for kwarg, classes in all_kwargs.items():
        if len(classes) == 1:
            # Don't want to print anything of the kwarg is unique and not removed.
            if kwarg not in removed_kwargs:
                print(f" | kwarg {kwarg} used by class {classes}")
        else:
            # Whether or not the kwargs is filled anywhere, if it is not unique we need to know.
            print(f" X CONFLICT WARNING: kwarg {kwarg} used by multiple classes: {classes}")
    print(" - Check complete.")
    print("------------------\n")

def helper_check_declared_attributes(cls):
    """
    Helper function that prints out all attributes of parent classes of the class you are checking.  This helps
    ensure that you are not overriding any parent class attributes, which is considered illegal by this project's
    style guide.  Prints a warning if any conflicts are discovered.

    :param cls: The class (must be a subclass of Payment, conforming to the style guide) you want to check.
    """
    all_attributes = {}

    # Ignore the last object in the MRO, which is object and so does not have 'attributes'
    for c in cls.mro()[:-1]:
        for attr in c.attributes:
            if attr in all_attributes.keys():
                all_attributes[attr].add(c.__name__)
            else:
                all_attributes[attr] = {c.__name__}

    print(f"Compiling parent attributes for class {cls}...")
    for attr, classes in all_attributes.items():
        if len(classes) == 1:
            print(f" | attribute {attr} used by class {classes}")
        else:
            print(f" X CONFLICT WARNING: attribute {attr} used by multiple classes: {classes}")
    print(" - Check complete.")
    print("------------------\n")

# ======================================================================================================================
# Payment subclass implementations below this line
# ======================================================================================================================

class PhysicalProduct(Payment):
    attributes = {"product_id", "shipping_address", "agent"}
    required_kwargs = {"product_id", "shipping_address", "agent"}
    filled_kwargs = set()

    def __init__(self, **kwargs):
        """
        Required kwargs:
            database
            value
            product_id
            shipping_address
            agent
        """
        super().__init__(**kwargs)
        self.product_id = kwargs["product_id"]
        self.shipping_address = kwargs["shipping_address"]
        self.agent = kwargs["agent"]

    def process_middle(self, processor):
        super().process_middle(processor)

        processor.generate_commission(self)

    def process_end(self, processor):
        processor.generate_packing_slip(self)

        super().process_end(processor)

class Book(PhysicalProduct):
    """
    Required kwargs:
        database
        value
        product_id
        shipping_address
        agent
    """
    attributes = set()
    required_kwargs = set()
    filled_kwargs = set()

    def process_middle(self, processor):
        super().process_middle(processor)

        processor.generate_royalty_packing_slip(self)

class Membership(Payment):
    attributes = {"membership_payment_type", "membership_id", "member_id"}
    required_kwargs = {"membership_payment_type", "membership_id", "member_id"}
    filled_kwargs = set()

    def __init__(self, **kwargs):
        """
        Required kwargs:
            database
            value
            membership_payment_type
            membership_id
            member_id
        """

        # Call parent constructor
        super().__init__(**kwargs)

        # Instantiate attributes
        self.membership_id = kwargs["membership_id"]
        self.member_id = kwargs["member_id"]
        ptype = kwargs["membership_payment_type"]
        if ptype == "upgrade" or ptype == "activation":
            self.membership_payment_type = ptype
        else:
            raise ValueError("Invalid argument: membership_payment_type must be either 'upgrade' or 'activation'.")

    def process_middle(self, processor):
        super().process_middle(processor)

        if self.membership_payment_type == "upgrade":
            processor.upgrade_membership(self)
        else:
            processor.activate_membership(self)

    def process_end(self, processor):
        processor.send_membership_email(self)

        super().process_end(processor)

class Video(PhysicalProduct):
    """
    Required kwargs:
        database
        value
        product_id
        shipping_address
        agent
    """
    def process_middle(self, processor):
        super().process_middle(processor)

        # Check whether an add-on product is required
        if self.product_id in self.database.video_addons.keys():
            processor.video_addon(self.database.video_addons[self.product_id])

