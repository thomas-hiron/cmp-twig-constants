local source = {}

local constantItems = {}

local function load_twig_constants()
  local handle = io.popen('rg --vimgrep --no-line-number --no-column "public const" src')
  local result = handle:read("*a")
  handle:close()

  constantItems = {}
  for line in result:gmatch("[^\r\n]+") do
    local fqcn, const, value = line:match("(.+): .+ ([A-Za-z0-9_]+) = (.+)")

    value = value == "[" and "Array" or value:gsub("[;']", "")
    fqcn = fqcn:gsub("src", "App"):gsub(".php", "")

    table.insert(constantItems, {
      label = fqcn:gsub(".+/", "") .. "::" .. const,
      insertText = fqcn:gsub("/", "\\\\") .. "::" .. const,
      documentation = {
        kind = 'markdown',
        value = '_Class_: ' .. fqcn .. '\n_Value_: ' .. value,
      }
    })
  end

  -- Reload in 60 seconds
  vim.defer_fn(load_twig_constants, 60000)
end

load_twig_constants()

function source.new()
  local self = setmetatable({}, { __index = source })
  return self
end

function source.get_debug_name()
  return 'twig'
end

function source.is_available()
  local filetypes = { 'twig' }

  return vim.tbl_contains(filetypes, vim.bo.filetype)
end

function source.get_trigger_characters()
  return { "'" }
end

function source.complete(self, request, callback)
  local line = vim.fn.getline('.')
  local triggers = { 'constant' }
  local found = false

  -- Trigger only if constant function is present on the line.
  for k, trigger in pairs(triggers) do
    if string.find(line:lower(), trigger) then
      found = true
    end
  end

  if not found then
    callback({isIncomplete = true})

    return
  end

  callback {
    items = constantItems,
    isIncomplete = true,
  }
end

return source
