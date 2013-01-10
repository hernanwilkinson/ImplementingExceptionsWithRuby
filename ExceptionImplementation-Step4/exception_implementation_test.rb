require 'test/unit'
require 'minitest/reporters'
MiniTest::Reporters.use!

class Proc

  def self.current_handler(handler)
    @current_handler = handler
  end

  def self.handle(an_exception)
    result = if an_exception.kind_of? @current_exception_to_handle_class
      result = @current_handler.call an_exception
    else
      an_exception.handler_not_found
    end

    @current_return_closure.call result

  end

  def self.current_return_closure(return_closure)
    @current_return_closure = return_closure
  end

  def self.current_exception_to_handle_class(an_exception_class)
    @current_exception_to_handle_class = an_exception_class
  end

  def call_handling(an_exception_class,&handler)
    self.class.current_handler handler
    self.class.current_return_closure proc { |an_object|
      return an_object }
    self.class.current_exception_to_handle_class an_exception_class

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

  def handler_not_found
    UnhandledException.throw
  end
end

class UnhandledException < NewException
  def self.handler_not_found_closure(a_closure)
    @handler_not_found_closure = a_closure
  end

  def self.default_handler_not_found_closure
    lambda { exit -1 }
  end

  def self.handler_not_found
    @handler_not_found_closure ||= default_handler_not_found_closure
    @handler_not_found_closure.call
  end

  def handler_not_found
    self.class.handler_not_found
  end
end

class NewExceptionSubclass < NewException

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

  def test_3
    UnhandledException.handler_not_found_closure(proc { 'Handler not found'})

    result = lambda {
      NewException.throw
      flunk }.call_handling NewExceptionSubclass do |an_exception |
      flunk
    end

    assert_equal 'Handler not found',result
  end
end