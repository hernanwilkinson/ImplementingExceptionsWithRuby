require 'test/unit'
require 'minitest/reporters'
MiniTest::Reporters.use!

class Proc

  def self.current_handler(an_exception_handler)
    @handler = an_exception_handler
  end

  def self.handle(an_exception)
    @handler.handle an_exception
  end

  def call_handling(an_exception_class,&handler)
    return_closure = proc { |an_object|
      return an_object }

    self.class.current_handler ExceptionHandler.new an_exception_class,handler,return_closure

    call
  end
end

class ExceptionHandler

  def handle(an_exception)
    result = if an_exception.kind_of? @exception_class
               result = @handler.call an_exception
             else
               an_exception.handler_not_found
             end

    @return_continuation.call result

  end

  def initialize(an_exception_class,handler,return_closure)
    @handler = handler
    @return_continuation = return_closure
    @exception_class = an_exception_class
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
  def self.handler_not_found_strategy(a_closure)
    @handler_not_found_strategy = a_closure
  end

  def self.default_handler_not_found_strategy
    lambda { exit -1 }
  end

  handler_not_found_strategy default_handler_not_found_strategy

  def self.handler_not_found
    @handler_not_found_strategy.call
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
    UnhandledException.handler_not_found_strategy(proc { 'Handler not found'})

    result = lambda {
      NewException.throw
      flunk }.call_handling NewExceptionSubclass do |an_exception |
      flunk
    end

    assert_equal 'Handler not found',result
  end

  def test_4
    UnhandledException.handler_not_found_strategy(proc { flunk })

    result = lambda {
      lambda {
        NewException.throw
        flunk }.call_handling NewExceptionSubclass do |an_exception |
        flunk
      end }.call_handling UnhandledException do | an_exception |
      2
    end

    assert_equal 2,result
    end
end