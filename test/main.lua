local csv = require('pretty-csv')

local csv_data = csv.readFile('payment_utf8.csv')
if not csv_data or csv_data == '' then
  print('Eror read: payment_utf8.csv')
  os.exit(0)
end

local csvTable, rowCount = csv.parse(csv_data, ',')

local total_sum = 0
for i = 1, #csvTable[6] do
  local item = csvTable[6][i]
  if csvTable[8][i] == 'Зачислен' then
    local sum = (tonumber(item:match('(%d+)')) or 0)
    total_sum = total_sum + sum
  end
end

csv.render(csvTable, rowCount)
print('\n Total RUB: '..total_sum)
