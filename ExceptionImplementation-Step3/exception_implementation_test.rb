require 'test/unit'
require 'minitest/reporters'
MiniTest::Reporters.use!

class Proc

  def self.current_handler(handler)
    @current_handler = handler
  end

  def self.handle(an_exception)
    result = @current_handler.call an_exception
    @current_return_closure.call result
  end

  def self.current_return_closure(return_closure)
    @current_return_closure = return_closure
  end

  def call_handling(an_exception_class,&handler)
    self.class.current_handler handler
    self.class.current_return_closure proc { |an_object|
      return an_object }

    call
  end
end

class NewException
  def self.throw
    self.new.throw
  end

  def throw
    Proc.handle self
  end
end

class ExceptionImplementationTest < Test::Unit::TestCase

  def test_1
    result = lambda { 1+1 }.call_handling Exception do |an_exception |
      flunk
    end

    assert_equal 2,result
  end

  def test_2
    result = lambda {
      NewException.throw
      flunk }.call_handling NewException do |an_exception |
      2
    end

    assert_equal 2,result
  end
end