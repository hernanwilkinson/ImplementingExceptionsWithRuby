require 'test/unit'
require 'minitest/reporters'
MiniTest::Reporters.use!

class Proc
  def call_handling(an_exception_class,&handler)
    return_continuation = proc { |an_object|
      return an_object }

    DefinedExceptionHandler.install_new_handler_while_evaluating self,an_exception_class,handler,return_continuation
  end
end

class ExceptionHandler
  def handle(an_exception)
    #implement in subclasses
    fail
  end
end

class UndefinedExceptionHandler < ExceptionHandler
  def handle(an_exception)
    an_exception.handler_not_found
  end
end

class DefinedExceptionHandler < ExceptionHandler

  @last_handler = UndefinedExceptionHandler.new

  def self.handle(an_exception)
    @last_handler.handle an_exception
  end

  def self.install_new_handler_while_evaluating(a_block,an_exception_class,handler,return_closure)
    @last_handler = self.new an_exception_class,handler,return_closure,@last_handler
    begin
      a_block.call
    ensure
      uninstall
    end
  end

  def previous
    @previous
  end

  def handle(an_exception)
    result = if should_handle? an_exception
               @handler.call an_exception
             else
               @previous.handle an_exception
             end

    @return_continuation.call result

  end

  def should_handle?(an_exception)
    an_exception.kind_of? @exception_class
  end

  def initialize(an_exception_class,handler,return_closure,previous)
    @handler = handler
    @return_continuation = return_closure
    @exception_class = an_exception_class
    @previous = previous
  end

  private
  def self.uninstall
    @last_handler = @last_handler.previous
  end
end

class NewException
  def self.throw
    self.new.throw
  end

  def throw
    DefinedExceptionHandler.handle self
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

  def test_when_no_exception_is_thrown_then_the_exception_handler_is_not_evaluted
    result = lambda { 1+1 }.call_handling Exception do |an_exception |
      flunk
    end

    assert_equal 2,result
  end

  def test_when_an_exception_is_thrown_then_the_exception_handler_is_evaluated
    result = lambda {
      NewException.throw
      flunk }.call_handling NewException do |an_exception |
      2
    end

    assert_equal 2,result
  end

  def test_when_an_exception_is_not_handle_then_handler_not_found_strategy_is_evaluated
    UnhandledException.handler_not_found_strategy(proc { 'Handler not found'})

    result = lambda {
      NewException.throw
      flunk }.call_handling NewExceptionSubclass do |an_exception |
      flunk
    end

    assert_equal 'Handler not found',result
  end

  def test_exception_handlers_can_be_nested
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