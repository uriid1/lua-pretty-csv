--------------------------------
-- CSV Parser/Render
--
-- Copyright (c) 2023 uriid1
-- License MIT
--------------------------------
local utf8 = require('utf8')

local COLOR = {
  reset ="\27[0m",
  gray = "\27[38;5;240m",
}
local function colorize(color, text)
  return color..text..COLOR.reset
end

local function readFile(filepath)
  local fd = io.open(filepath, 'r')
  if not fd then
    return nil
  end
  local data = fd:read('*a')
  fd:close()

  return data
end

local function parse(csv_data, csv_sep)
  local result = {}
  local index = 0

  local rowCount = 0
  for column in string.gmatch(csv_data, '.-\n') do
    local inQuotes = false
    local resRowStr = ''
    for i = 1, #column do
      local char = column:sub(i, i)
      if char == csv_sep and not inQuotes then

        index = index + 1
        if not result[index] then
          result[index] = {}
        end
        table.insert(result[index], resRowStr)

        resRowStr = ''
        goto continue
      end
      if char == '"' then
        inQuotes = not inQuotes
      end
      resRowStr = resRowStr .. char
      ::continue::
    end

    rowCount = rowCount + 1
    index = 0
  end

  return result, rowCount
end

local function getMaxRowLen(csvTable, column)
  local maxLen = 0
  for i = 1, #csvTable[column] do
    local len = utf8.len(csvTable[column][i])
    if len > maxLen then
      maxLen = len
    end
  end
  return maxLen
end

local function render(csvTable, rowCount)
  local csvTableLen = #csvTable
  local result = ''

  for item = 1, rowCount do
    local lenRows = {}
    for column = 1, csvTableLen do
      local maxLen = getMaxRowLen(csvTable, column)
      local curItem = csvTable[column][item]
      if not curItem then
        goto continue
      end

      result = result .. colorize(COLOR.gray, '│ ')

      local len = maxLen - utf8.len(curItem) + 1
      table.insert(lenRows, maxLen)

      result = result .. curItem..string.rep(' ', len)

      if column == csvTableLen then
        result = result .. colorize(COLOR.gray, '│')
      end

      ::continue::
    end

    result = result .. '\n'
    result = result .. colorize(COLOR.gray, '├')

    for i = 1, #lenRows do
      local len = lenRows[i]

      result = result .. colorize(COLOR.gray, string.rep('─', len + 2))
      if i == #lenRows then
        result = result .. colorize(COLOR.gray, '┤')
      else
        result = result .. colorize(COLOR.gray, '┼')
      end
    end

    result = result .. '\n'
  end

  io.write(result)
end

return {
  readFile = readFile,
  parse = parse,
  render = render,
}
