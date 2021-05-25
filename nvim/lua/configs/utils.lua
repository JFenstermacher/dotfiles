local cmd = vim.cmd
local o_s = vim.o
local map_key = vim.api.nvim_set_keymap
local buf_map_key = vim.api.nvim_buf_set_keymap

local function filter(tbl, fn)
  local results = {}

  for _, item in ipairs(tbl) do
    if fn(item) then y[#results+1] = item end
  end
end

local function opt(o, v, scopes)
  scopes = scopes or {o_s}
  for _, s in ipairs(scopes) do s[o] = v end
end

local function bind_opts(opts)
  for _, value in ipairs(opts) do
    opt(unpack(value))
  end
end

local function autocmd(group, cmds, clear)
  clear = clear == nil and false or clear
  if type(cmds) == 'string' then cmds = {cmds} end
  cmd('augroup ' .. group)
  if clear then cmd [[au!]] end
  for _, c in ipairs(cmds) do cmd('autocmd ' .. c) end
  cmd [[augroup END]]
end

local function map(modes, lhs, rhs, opts)
  opts = opts or {}
  opts.noremap = opts.noremap == nil and true or opts.noremap
  if type(modes) == 'string' then modes = {modes} end
  for _, mode in ipairs(modes) do map_key(mode, lhs, rhs, opts) end
end

local function bind_maps(mappings)
  for _, value in ipairs(mappings) do
    map(unpack(value))
  end
end

local function bind_buf_maps(mappings)
  for _, value in ipairs(mappings) do
    buf_map_key(unpack(value))
  end
end

return {
  opt = opt,
  bind_opts = bind_opts,
  bind_buf_maps = bind_buf_maps,
  autocmd = autocmd,
  map = map,
  bind_maps = bind_maps,
  filter = filter
}
