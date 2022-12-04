local pack = "packer"

local function bootstrap (url)
	local name = url:gsub(".*/", "")
	local path = vim.fn.stdpath [[data]] .. "/site/pack/".. pack .. "/start/" .. name

	if vim.fn.isdirectory(path) == 0 then
		print(name .. ": installing in data dir...")

		vim.fn.system {"git", "clone", "--depth", "1", url, path}

		vim.cmd [[redraw]]
		print(name .. ": finished installing")
	end
end

bootstrap "https://github.com/lewis6991/impatient.nvim"
bootstrap "https://github.com/udayvir-singh/tangerine.nvim"
bootstrap "https://github.com/udayvir-singh/hibiscus.nvim"

require [[impatient]]

require [[tangerine]].setup{
  rtpdirs = {
    "after"
  },
  compiler = {
    verbose = false,
    hooks = {"oninit", "onsave"}
  }
}