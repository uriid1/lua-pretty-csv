local csv = require('pretty-csv')

local data = csv.parse('payment.csv', { sep = ',', limit = 20, word_len = 30 })
csv.render(data)

local total_sum = 0
for i = 1, #data.csv[6] do
 local item = data.csv[6][i]
 if data.csv[8][i] == 'Зачислен' then
   local sum = (tonumber(item:match('(%d+)')) or 0)
   total_sum = total_sum + sum
 end
end
print('\n Total RUB: '..total_sum)