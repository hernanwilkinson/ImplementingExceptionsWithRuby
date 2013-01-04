
result = begin
  1/0
rescue Exception => an_exception
  2+2
end

puts result

