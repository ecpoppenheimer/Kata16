# frozen_string_literal: true

require '../payment'
require 'rspec/autorun'

class Tortilla
  @attributes = Set['grain'].freeze
  class << self
    attr_reader :attributes
  end
  @required_kwargs = Set['grain'].freeze
  class << self
    attr_reader :required_kwargs
  end
  @filled_kwargs = Set[].freeze
  class << self
    attr_reader :filled_kwargs
  end

  attr_reader :grain

  def initialize(**kwargs)
    @grain = kwargs[:grain]
  end
end

class Taco < Tortilla
  @attributes = Set['meat', 'cheese'].freeze
  class << self
    attr_reader :attributes
  end
  @required_kwargs = Set['meat', 'cheese'].freeze
  class << self
    attr_reader :required_kwargs
  end
  @filled_kwargs = Set[].freeze
  class << self
    attr_reader :filled_kwargs
  end

  attr_reader :meat, :cheese

  def initialize(**kwargs)
    super(**kwargs)
    @meat = kwargs[:meat]
    @cheese = kwargs[:cheese]
  end
end

class Meal < Taco
  @attributes = Set['drink'].freeze
  class << self
    attr_reader :attributes
  end
  @required_kwargs = Set['drink'].freeze
  class << self
    attr_reader :required_kwargs
  end
  @filled_kwargs = Set['grain'].freeze
  class << self
    attr_reader :filled_kwargs
  end

  attr_reader :drink

  def initialize(**kwargs)
    kwargs[:grain] = :flour
    super(**kwargs)
  end
end

class ComboMeal < Meal
  @attributes = Set['meat'].freeze
  class << self
    attr_reader :attributes
  end
  @required_kwargs = Set['meat'].freeze
  class << self
    attr_reader :required_kwargs
  end
  @filled_kwargs = Set[].freeze
  class << self
    attr_reader :filled_kwargs
  end

  attr_reader :meat

  def initialize(**kwargs)
    super(**kwargs)
    @meat = kwargs[:meat]
  end
end

describe 'helper_check_required_kwargs' do
  it 'collects the correct set of required kwargs' do
    expect { helper_check_required_kwargs(Meal) }.to output(a_string_including('drink')).to_stdout
    expect { helper_check_required_kwargs(Meal) }.to output(a_string_including('meat')).to_stdout
    expect { helper_check_required_kwargs(Meal) }.to output(a_string_including('cheese')).to_stdout
  end
  it 'ignores a removed kwarg' do
    expect { helper_check_required_kwargs(Meal) }.to_not output(a_string_including('grain')).to_stdout
  end
  it 'correctly identifies a conflict' do
    expect { helper_check_required_kwargs(ComboMeal) }.to output(a_string_including('CONFLICT')).to_stdout
  end
  it "doesn't flag a non-existing conflict" do
    expect { helper_check_required_kwargs(Meal) }.to_not output(a_string_including('CONFLICT')).to_stdout
  end
end

describe 'helper_check_declared_attributes' do
  it 'collects the correct set of declared attributes' do
    expect { helper_check_required_kwargs(Meal) }.to output(a_string_including('drink')).to_stdout
    expect { helper_check_required_kwargs(Meal) }.to output(a_string_including('meat')).to_stdout
    expect { helper_check_required_kwargs(Meal) }.to output(a_string_including('cheese')).to_stdout
  end
  it 'correctly identifies a conflict' do
    expect { helper_check_required_kwargs(ComboMeal) }.to output(a_string_including('CONFLICT')).to_stdout
  end
  it "doesn't flag a non-existing conflict" do
    expect { helper_check_required_kwargs(Meal) }.to_not output(a_string_including('CONFLICT')).to_stdout
  end
end
