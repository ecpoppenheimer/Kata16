"""
This script is for testing the payment helper functions
"""

from database import Database
from processor import Processor
import payment

db = Database()
processor = Processor(db)

class Tortilla:
    attributes = {"corn"}

class Taco(Tortilla):
    attributes = {"cheese", "meat"}

class Burrito(Tortilla):
    attributes = {"beans", "meat"}

class Salad:
    attributes = {"lettuce", "dressing", "tomato"}

class Desert:
    attributes = {"chocolate", "ice_cream"}

class Meal(Taco, Burrito):
    attributes = {"soda"}

class BigMeal(Meal, Desert):
    attributes = {}

payment.helper_check_declared_attributes(BigMeal)

print("======================================================================")

class Tortilla:
    required_kwargs = {"corn"}
    filled_kwargs = set()

class Taco(Tortilla):
    required_kwargs = {"cheese", "meat"}
    filled_kwargs = set()

class Burrito(Tortilla):
    required_kwargs = {"beans", "meat"}
    filled_kwargs = set()

class Salad:
    required_kwargs = {"lettuce", "dressing", "tomato"}
    filled_kwargs = set()

class Desert:
    required_kwargs = {"chocolate", "ice_cream"}
    filled_kwargs = set()

class Meal(Taco, Salad):
    required_kwargs = {"soda"}
    filled_kwargs = {"beans"}

class BigMeal(Meal, Desert):
    required_kwargs = {}
    filled_kwargs = {"soda", "dressing"}

payment.helper_check_required_kwargs(BigMeal)

