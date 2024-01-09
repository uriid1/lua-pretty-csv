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
  gray_number = "\27[38;5;245m",
}

local function cprint(text, color, nocolor)
  if nocolor then
    io.write(text)
  end

  io.write(color..text..COLOR.reset)
end

local special = {
  ['\a'] = true,
  ['\b'] = true,
  ['\t'] = true,
  ['\n'] = true,
  ['\v'] = true,
  ['\f'] = true,
  ['\r'] = true,
}

-- http://lua-users.org/lists/lua-l/2014-04/msg00590.html
local function utf8_sub(s,i,j)
   i = i or 1
   j = j or -1

   if (i < 1) or (j < 1) then
      local n = utf8.len(s)
      if not n then
        return nil
      end

      if i < 0 then i = n + 1 + i end
      if j < 0 then j = n + 1 + j end
      if i < 0 then i = 1 elseif i > n then i = n end
      if j < 0 then j = 1 elseif j > n then j = n end
   end
   if j < i then return '' end
   i = utf8.offset(s, i)
   j = utf8.offset(s, j + 1)
   if i and j then return s:sub(i, j - 1)
      elseif i then return s:sub(i)
      else return ''
   end
end

local function parse(filepath, param)
  local csv = {}
  local rowLen = {}
  local csvIndex = 0

  local sep = param.sep or ','
  local limit = param.limit or -1
  local max_word_len = param.word_len

  local rowCount = 0
  for column in io.lines(filepath, "*l") do
    local inQuotes = false
    local resRowStr = ''
    local curLen = 0

    local columnLen = #column
    for i = 1, columnLen do
      local char = utf8_sub(column, i, i)

      if char == '"' then
        inQuotes = not inQuotes
      end

      if char == sep and not inQuotes then
        csvIndex = csvIndex + 1

        if max_word_len and curLen > max_word_len then
          resRowStr = utf8_sub(resRowStr, 1, max_word_len - 3)..'...'
          curLen = max_word_len
        end

        if not csv[csvIndex] then
          csv[csvIndex] = {}
          rowLen[csvIndex] = {}
        end
        table.insert(csv[csvIndex], resRowStr)
        table.insert(rowLen[csvIndex], curLen)

        curLen = 0
        resRowStr = ''
      else
        if not special[char] then
          resRowStr = resRowStr .. char
          curLen = curLen + 1
        end
      end
    end

    csvIndex = csvIndex + 1

    local strLen = utf8.len(resRowStr)
    if max_word_len and strLen > max_word_len then
      resRowStr = utf8_sub(resRowStr, 1, max_word_len - 3)..'...'
    end

    if not csv[csvIndex] then
      csv[csvIndex] = {}
      rowLen[csvIndex] = {}
    end
    table.insert(csv[csvIndex], resRowStr)
    table.insert(rowLen[csvIndex], strLen)

    if limit ~= -1 and limit == rowCount then
      break
    end

    rowCount = rowCount + 1
    csvIndex = 0
  end

  local result = {
    csv = csv,
    row_count = rowCount,
    row_len = rowLen,
    param = param,
  }

  return result
end

local function getMaxRowLen(csv, column)
  local maxLen = 0
  for i = 1, #csv[column] do
    local len = csv[column][i]
    if len > maxLen then
      maxLen = len
    end
  end
  return maxLen
end

local function render(csv_table)
  local csvTableLen = #csv_table.csv
  local rowCount = csv_table.row_count
  local csv = csv_table.csv

  --
  -- Header
  --
  cprint('┌', COLOR.gray)
  local maxLen = {}
  for i = 1, #csv_table.row_len do
    local len = getMaxRowLen(csv_table.row_len, i)
    table.insert(maxLen, len)

    local pos = ' '..i ..' '
    cprint(pos, COLOR.gray_number)
    cprint(string.rep('─', len - #pos + 2), COLOR.gray)

    if i == #csv_table.row_len then
      cprint('┐', COLOR.gray)
    else
      cprint('┐', COLOR.gray)
    end
  end
  io.write('\n')

  --
  -- Body
  --
  for item = 1, rowCount do
    local lenRows = {}
    for column = 1, csvTableLen do
      local maxLen = maxLen[column]
      local curItem = csv[column][item]
      if not curItem then
        goto continue
      end

      cprint('│ ', COLOR.gray)

      local len = maxLen - utf8.len(curItem) + 1
      table.insert(lenRows, maxLen)

      io.write(curItem..string.rep(' ', len))

      if column == csvTableLen then
        cprint('│', COLOR.gray)
        cprint(' '..item, COLOR.gray_number)
      end

      ::continue::
    end

    io.write('\n')

    if item ~= rowCount then
      cprint('├', COLOR.gray)
      for i = 1, #lenRows do
        local len = lenRows[i]

        cprint(string.rep('─', len + 2), COLOR.gray)
        if i == #lenRows then
          cprint('┤', COLOR.gray)
        else
          cprint('┼', COLOR.gray)
        end
      end

      io.write('\n')
    end
  end

  --
  -- End
  --
  cprint('└', COLOR.gray)
  for i = 1, #maxLen do
    cprint(string.rep('─', maxLen[i] + 2), COLOR.gray)

    if i == #csv_table.row_len then
      cprint('┘', COLOR.gray)
    else
      cprint('┴', COLOR.gray)
    end
  end
  io.write('\n')
end

return {
  parse = parse,
  render = render,
}
