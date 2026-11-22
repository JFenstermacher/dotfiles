vim.opt.modeline = false
vim.opt.termguicolors = true
vim.api.nvim_set_hl(0, "Normal", {}) -- Use Rex's default foreground and background.
vim.opt.laststatus = 2
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false
local statusline = " Rex Copy Mode  |  v/V/Ctrl-V select  y copy  q quit%=%l/%L "
vim.opt.statusline = statusline
vim.g.clipboard = "osc52" -- Let Rex deliver the copy to the viewing client's clipboard.

local buf = vim.api.nvim_get_current_buf()
vim.bo[buf].buftype = "nofile"
vim.bo[buf].bufhidden = "wipe"
vim.keymap.set("n", "q", "<Cmd>qa!<CR>", { buffer = buf })

local max_lines = 5000
local max_capture_bytes = 128 * 1024 -- VT bytes, including color codes.

local function capture_vt()
  local command = {
    "rex", "block", "call", "--session", assert(vim.env.REX_COPY_SESSION),
    "--block", assert(vim.env.REX_COPY_BLOCK),
  }
  local function call(method, args)
    local result = vim.system(vim.list_extend(vim.list_slice(command), { method, vim.json.encode(args) })):wait()
    if result.code ~= 0 then error("Rex capture failed: " .. result.stderr, 0) end
    return vim.json.decode(result.stdout)
  end

  local first = call("format", {
    format = "vt", trim = true, unwrap = true, extra_palette = true, max_bytes = max_capture_bytes,
  })
  -- Palette definitions are at the start of the snapshot, even when we skip older text.
  local palette_end = 0
  while first.content:sub(palette_end + 1, palette_end + 4) == "\27]4;" do
    local _, stop = first.content:find("\27\\", palette_end + 5, true)
    if not stop then break end
    palette_end = stop
  end

  local offset = #first.content
  local vt = first.content:sub(palette_end + 1)
  local tail_offset = (first.total or offset) - max_capture_bytes
  local truncated = tail_offset > palette_end
  if first.id then
    -- One reply fits the tail even with JSON escaping. Skip through the first newline
    -- when jumping into the tail: the starting byte can bisect UTF-8 or a VT escape.
    local part = call("blob_read", {
      id = first.id, offset = truncated and tail_offset - 1 or offset, max_bytes = 960 * 1024,
    })
    if not part.eof then error("Rex returned an incomplete capture tail", 0) end
    if truncated then
      local newline = part.data:find("\n", 1, true)
      vt = newline and part.data:sub(newline + 1) or ""
    else
      vt = vt .. part.data
    end
  end

  local reversed, newline = vt:reverse(), 0
  for _ = 1, max_lines do
    newline = reversed:find("\n", newline + 1, true)
    if not newline then break end
  end
  if newline then
    vt = vt:sub(#vt - newline + 2)
    truncated = true
  end
  return first.content:sub(1, palette_end) .. vt, truncated
end

local sgr_styles = {
  ["1"] = "bold", ["3"] = "italic", ["4"] = "underline", ["4:2"] = "underdouble",
  ["4:3"] = "undercurl", ["4:4"] = "underdotted", ["4:5"] = "underdashed",
  ["7"] = "reverse", ["9"] = "strikethrough",
}
local sgr_colors = { ["38"] = "fg", ["48"] = "bg", ["58"] = "sp" }

-- Rex serializes style changes as a reset followed by individual SGR codes.
-- Decode the snapshot, never replay it in a terminal or put escapes in the buffer.
local function render(vt)
  local lines, spans, palette, groups = {}, {}, {}, {}
  local style, style_key, group_count = {}, "", 0
  local ns = vim.api.nvim_create_namespace("rex-copy-mode")

  for line in vim.gsplit(vt, "\r?\n") do
    local parts, col, pos = {}, 0, 1
    local function append(text)
      if text == "" then return end
      parts[#parts + 1] = text
      if style_key ~= "" then
        if not groups[style_key] then
          group_count = group_count + 1
          groups[style_key] = "RexCopyStyle" .. group_count
          vim.api.nvim_set_hl(0, groups[style_key], style)
        end
        spans[#spans + 1] = { #lines, col, col + #text, groups[style_key] }
      end
      col = col + #text
    end

    while pos <= #line do
      local esc = line:find("\27", pos, true)
      if not esc then
        append(line:sub(pos))
        break
      end
      append(line:sub(pos, esc - 1))

      local params, kind, next_pos = line:match("^\27%[([%d;:]*)(%a)()", esc)
      if kind == "m" then
        if params == "0" then
          style, style_key = {}, ""
        else
          local key, value = sgr_styles[params], true
          local code, index = params:match("^(%d+);5;(%d+)$")
          if code then
            key, value = sgr_colors[code], palette[index]
          else
            local rgb, r, g, b = params:match("^(%d+);2;(%d+);(%d+);(%d+)$")
            if rgb then key, value = sgr_colors[rgb], ("#%02x%02x%02x"):format(r, g, b) end
          end
          if key and value then
            style[key] = value
            style_key = style_key .. ";" .. params
          end
        end
      elseif kind == "C" then
        -- Rex advances past blank cells with CSI C (sometimes preceded by CSI X).
        append(string.rep(" ", tonumber(params) or 1))
      elseif line:sub(esc + 1, esc + 1) == "]" then
        local stop = line:find("\27\\", esc + 2, true)
        if not stop then break end
        local index, r, g, b = line:sub(esc + 2, stop - 1):match("^4;(%d+);rgb:(%x%x)/(%x%x)/(%x%x)$")
        if index then palette[index] = "#" .. r .. g .. b end
        next_pos = stop + 2 -- Drop palette definitions and hyperlink metadata from the text.
      end
      pos = next_pos or esc + 1
    end
    lines[#lines + 1] = (table.concat(parts):gsub(" +$", ""))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for _, span in ipairs(spans) do
    local row, first, last, hl = unpack(span)
    local end_col = math.min(last, #lines[row + 1])
    if first < end_col then
      vim.api.nvim_buf_set_extmark(buf, ns, row, first, { end_col = end_col, hl_group = hl })
    end
  end
  vim.api.nvim_win_set_cursor(0, { #lines, 0 })
end

local vt, truncated = capture_vt()
render(vt)
if truncated then vim.opt.statusline = " [capped]" .. statusline end
vim.bo[buf].modifiable = false

vim.api.nvim_create_autocmd("TextYankPost", {
  buffer = buf,
  callback = function()
    local yank = vim.v.event
    if yank.operator ~= "y" then return end
    -- Explicit "+ yanks already use the clipboard provider. Route other yanks there too.
    if yank.regname ~= "+" then vim.fn.setreg("+", yank.regcontents, yank.regtype) end
    vim.schedule(function() vim.cmd("qa!") end)
  end,
})
