local configs = {}

function configs.gruvbox_material()
  vim.cmd('colorscheme gruvbox-material')
end

function configs.lualine()
  require('lualine').setup{
    options = { theme = 'gruvbox' }
  }
end

function configs.dashboard_nvim()
  local db = require('dashboard')

  db.custom_header = {
     "                                   ",
     "                                   ",
     "                                   ",
     "   ⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣿⣶⣿⣦⣼⣆          ",
     "    ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦       ",
     "          ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷    ⠻⠿⢿⣿⣧⣄     ",
     "           ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄    ",
     "          ⢠⣿⣿⣿⠈    ⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀   ",
     "   ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘  ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄  ",
     "  ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄   ",
     " ⣠⣿⠿⠛ ⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄  ",
     " ⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇ ⠛⠻⢷⣄ ",
     "      ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆     ",
     "       ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⣀⣤⣾⡿⠃     ",
     "                                   ",
  }

  db.custom_center = {
    {
      icon = ' ',
      desc = 'Update Plugins                           ',
      shortcut = 'SPC p u',
      action = 'PackerUpdate',
    },
    {
      icon = ' ',
      desc = 'Find File                                ',
      action = 'Telescope find_files find_command=rg,--hidden,--files',
      shortcut = 'SPC f f',
    },
    {
      icon = ' ',
      desc = 'Recents                                  ',
      shortcut = 'SPC f o',
      action = 'Telescope oldfiles'
    },
    {
      icon = ' ',
      desc = 'Find Word                                ',
      shortcut = 'SPC f w',
      action = 'Telescope live_grep'
    },
  }

  db.hide_statusline = true
end

return configs
