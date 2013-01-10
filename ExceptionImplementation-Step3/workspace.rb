
def returnFromLambda
  result = lambda { return 5 }.call
  return result + 10
end

def returnFromClosure
  result = proc { return 5 }.call
  return result + 10
end

puts returnFromLambda
puts returnFromClosure

