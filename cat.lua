#!/usr/bin/env luvit

getmetatable('').__concat = function(a, b)
  p('CCAT', a, b)
  return tostring(a) .. tostring(b)
end

print('1' .. '2')
print(1 .. '2')
print('1' .. 2)
print(1 .. 2)

print('1' .. nil)
print(nil .. '1')

--print(nil .. p)
print('1' .. {1,2,3})
print(tostring({1,2,3}))
