
local require_ok, locals = pcall(require, "nvim-treesitter.locals")
local _, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
local _, utils = pcall(require, "nvim-treesitter.utils")
local _, parsers = pcall(require, "nvim-treesitter.parsers")
local _, queries = pcall(require, "nvim-treesitter.query")


P = function(v)
  print(vim.inspect(v))
  return v
end

function myConcat(t1, t2)
  local res = {}
  for _, value in pairs(t1) do
    table.insert(res, value)
  end

  for _, value in pairs(t2) do
    table.insert(res, value)
  end
  return res
end

function PT(table)
  io.write('{')
  for _, value in pairs(table) do
    io.write(value, ',')
  end
  io.write('}\n')
end

function fullConcat(array)
  if #array < 2 then
    error("Need a table with more or equal to 2 arguments")
  end

  local res = myConcat(array[1], array[2])

  if #array == 2 then
    return res
    else
      for i=3, #array do
        res = myConcat(res, array[i])
      end
  end

  return res
end

RELOAD = function(package)
  package.loaded[package] = nil
  return require(package)
end

local function getLocals()
  local nodes = locals.get_local_nodes(locals.get_locals())
  return nodes
end

local function getFields()
  local fields = {}
  local buf = vim.fn.nvim_get_current_buf()

  local definitions = locals.get_definitions(buf)
  for _, d in pairs(definitions) do
    local node = utils.get_at_path(d, 'field.node')
    if node then
      local name = ts_utils.get_node_text(node, buf)[1]

      local firstLetterUpper = string.upper(string.sub(name, 1, 1))

      local res = "get" .. firstLetterUpper .. string.sub(name, 2) .. "()"
      local range = ts_utils.get_node_range(node)
      table.insert(fields, {res, range});
    end
  end
  return fields
end


local function generate_fun_definition(field_name)
  local first_part = "public function "
  local indent = string.rep(" ", vim.bo.tabstop);

  local firstLetterUpper = string.upper(string.sub(field_name, 1, 1))

  local method = "get" .. firstLetterUpper .. string.sub(field_name, 2) .. "()"


  local definition = indent .. first_part .. method

  local second_line = indent .. "{"

  -- segundo nivel de indentacion (cuerpo de la funcion)
  local third_line = string.rep(indent, 2) .. "return $this->" .. field_name .. ";"

  local fourth_line = indent .. "}"

  return {"", definition, second_line, third_line, fourth_line}
end




local function asd()
  local query = [[
  (property_declaration
    (property_element
      (variable_name
        (name) @propName
          )
        )
      )]]

  local parsedQ = vim.treesitter.parse_query("php", query)
  -- print(vim.inspect(res))

  local win_height = vim.fn.nvim_win_get_height(0)

  local buf = vim.fn.nvim_get_current_buf()

  -- vim.fn.nvim_buf_set_lines(buf, -1, -1, false, {"asd"})
  local lines = vim.fn.nvim_buf_get_lines(buf, -3, -1, false)



  local results = getLocals()

  -- vim.fn.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(vim.inspect(results), "\n"))


  local scopes = locals.get_scopes(buf)

  local query_fields = {}
  local func_strings = {}
  for _, node in pairs(scopes) do

    -- P(node:type())
    if node:type() == "class_declaration" then

      -- P(getmetatable(node))


      -- local bufnr = 60
      -- local results = {}
      -- for key,value in pairs(getmetatable(node)) do
      --   table.insert(results, {key, value})
      -- end
      -- vim.fn.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(vim.inspect(results), "\n"))


      for id, innerNode, metadata in parsedQ:iter_captures(node, bufnr) do
        local name = parsedQ.captures[id] -- name of the capture in the query

        -- typically useful info about the node:
        local type = innerNode:type() -- type of the captured node
        local row1, col1, row2, col2 = innerNode:range() -- range of the capture

        local node_name = ts_utils.get_node_text(innerNode, buf)[1]


        local firstLetterUpper = string.upper(string.sub(node_name, 1, 1))

        local res = "get" .. firstLetterUpper .. string.sub(node_name, 2) .. "()"

        table.insert(query_fields, {res, row2 + 1});
        table.insert(func_strings, generate_fun_definition(node_name))

        -- P(getmetatable(innerNode))

        ::continue::
      end
      local buf = 5

      -- P(func_strings)
      local concat = fullConcat(func_strings)
      P(concat)
      local _,_, class_declaration_end_idx,_ = node:range()

      vim.fn.append(class_declaration_end_idx, concat)


      -- print('concat', #concat)

      -- vim.fn.nvim_buf_set_lines(buf, -1, -1, false, concat)

      -- P(func_strings)

    end
  end


  -- TODO:  <02-04-21, yourname> --

  -- get scopes -> query for props -> generate getters and setters ->
  --  -> append at end of file
end



local function insert_data()
  -- local buf = vim.fn.nvim_get_current_buf()
  -- vim.fn.nvim_buf_set_lines(buf, 182, -1, false, {"}", "asd", "}"})
  -- vim.fn.append(183, {"", "    public function aasd()", "    {", "        return $this->asd;", "    }"})
  vim.fn.append(183, generate_fun_definition("data"))
  -- vim.fn.nvim_buf_set_text(buf, 183, 5, 188, 100, {"public function aasd()", "{", "", "return $this->asd;", "}"})

end



local function asd2()
  local buf = vim.fn.nvim_get_current_buf()

  local scopes = locals.get_scopes(buf)

  for _, node in pairs(scopes) do
    if node:type() == "method_declaration" then
      local range, _ ,_ ,_ = node:range()
      print(range .. "----- start------\n")
      for _, child in node:iter_children() do
        print((child))
      end
      print(range .. "-----end----")

    end
  end

end


return {
  asd = asd,
  insert_data = insert_data,
  autocomplete_constructor = asd2
}
