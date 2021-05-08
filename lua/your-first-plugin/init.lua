
local require_ok, locals = pcall(require, "nvim-treesitter.locals")
local _, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
local _, utils = pcall(require, "nvim-treesitter.utils")
local _, parsers = pcall(require, "nvim-treesitter.parsers")
local _, queries = pcall(require, "nvim-treesitter.query")

P = function(v)
  print(vim.inspect(v))
  return v
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
  for _, node in pairs(scopes) do

    P(node:type())
    if node:type() == "class_declaration" then

      P("childN" .. node:end_())


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


      end
      P(query_fields)

    end
    ::continue::
  end


  -- TODO:  <02-04-21, yourname> --

  -- get scopes -> query for props -> generate getters and setters ->
  --  -> append at end of file
end

local function insert_data()
  local buf = vim.fn.nvim_get_current_buf()
  -- vim.fn.nvim_buf_set_lines(buf, 182, -1, false, {"}", "asd", "}"})
  -- vim.fn.append(183, {"", "    public function aasd()", "    {", "        return $this->asd;", "    }"})
  -- vim.fn.append(183, {"", "", "", "", ""})
  -- vim.fn.nvim_buf_set_text(buf, 183, 5, 188, 100, {"public function aasd()", "{", "", "return $this->asd;", "}"})
  P(vim.bo.tabstop)

end


return {
  asd = asd,
  insert_data = insert_data
}
