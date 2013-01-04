require 'test/unit'
require 'minitest/reporters'
MiniTest::Reporters.use!

class Proc
  def call_handling(an_exception_call,&handler)
    call
  end
end
class ExceptionImplementationTest < Test::Unit::TestCase

  def test_1
    result = lambda { 1+1 }.call_handling Exception do |an_exception|
      flunk
    end

    assert_equal 2,result

  end
end