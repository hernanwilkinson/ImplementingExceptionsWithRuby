require 'test/unit'
require 'minitest/reporters'
MiniTest::Reporters.use!

class Proc

  def self.current_handler(handler)
    @currentHandler = handler
  end

  def self.handle(an_exception)
    @currentHandler.call an_exception
  end

  def call_handling(an_exception_call,&handler)
    self.class.current_handler handler
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
    result = lambda { 1+1 }.call_handling Exception do |an_exception|
      flunk
    end

    assert_equal 2,result
  end

  def test_2
    result = lambda { NewException.throw }.call_handling NewException do |an_exception|
      2
    end

    assert_equal 2,result
  end



end