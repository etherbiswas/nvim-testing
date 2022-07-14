--[[
  Main Neovim configuration. Aims to be mostly language agnostic. Code which is
  language specific and buffer-local was moved to corresponding ftplugins in
  the directory "ftplugin" instead. Also, larger chunks of coherent code were
  refactored into libraries in "lua" or plugins in "plugin" to not clutter the
  main configuration file.
--]]

-------------------------------------------------------------------------------
-- {{{ Generic Configuration
-------------------------------------------------------------------------------

-- Options
-------------------------------------------------------------------------------

-- smart search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- tabs are two spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.bo.fileencoding = "utf8"
-- line break configuration
vim.opt.textwidth = 79
vim.opt.colorcolumn = {80, 120}
vim.opt.breakindent = true
vim.opt.linebreak = true

-- set list chars for horizontal scrolling
vim.opt.listchars:append{tab = "» ", precedes = "<", extends = ">"}
vim.opt.list = false

-- built-in completion & tag search
vim.opt.completeopt:append{"menuone", "noinsert"}
vim.opt.complete:remove{"t"}
vim.opt.omnifunc = "v:lua.vim.lsp.omnifunc"             -- neovim internal lsp completion
vim.opt.completefunc = "v:lua.vim.luasnip.completefunc" -- custom snippet completion defined in plugin/snipcomp.lua
vim.opt.tagfunc = "v:lua.vim.lsp.tagfunc"               -- interface to normal mode commands like CTRL-]

-- show line numbers and highlight cursor line number
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = { "number", "line" }

-- spell checking
vim.opt.spell = false
vim.opt.spelllang = {"en_us", "de_de", "cjk"}
vim.opt.spellfile = vim.fn.expand("~/.local/share/nvim/site/spell/spf.%s.add"):format(vim.o.encoding)
vim.opt.thesaurusfunc = "v:lua.vim.openoffice.thesaurusfunc" -- support openoffice thesauri, see plugin/thesaurus.lua
vim.opt.thesaurus = {
  -- archlinux packages extra/mythes-{en,de,..}
  "/usr/share/mythes/th_en_US_v2.dat",
  "/usr/share/mythes/th_de_DE_v2.dat"
}

-- mouse and clipboard integration
vim.opt.clipboard = "unnamedplus"
vim.opt.backup = false
vim.opt.mouse = "a"

-- set an alternative layout that can be switched to in insert mode with CTRL-^
--vim.opt.keymap = "kana"
--vim.opt.iminsert = 0

vim.opt.termguicolors = true   -- 24-bit RGB color in the TUI
vim.opt.undofile = true        -- persistent undo history
vim.opt.swapfile = false
vim.opt.showmode = false       -- do not show mode message on last line
vim.opt.hidden = true          -- switch buffers without having to save changes
vim.opt.joinspaces = false     -- insert one space when joining two sentences
vim.opt.confirm = true         -- raise dialog asking to save changes when commands like ':q' fail
vim.opt.title = true           -- set terminal window title to something descriptive
--vim.opt.foldlevel = 99         -- do not automatically close folds when editing a file
vim.opt.inccommand = "nosplit" -- show incremental changes of commands such as search & replace
vim.opt.virtualedit = "block"  -- virtual editing in visual block mode
vim.opt.shortmess:append("I")  -- don't give intro message when starting vim

-- Variables
-------------------------------------------------------------------------------

-- define leaders for use in keybindings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- syntax related global variables
vim.g.sh_no_error = true
vim.g.readline_has_bash = true
vim.g.tex_flavor = "latex"
vim.g.markdown_fenced_languages = {"sh", "python", "lua"}

-- setup netrw and viewer for 'gx' mapping
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
--vim.g.netrw_browse_split = 4
vim.g.netrw_winsize = 25
vim.g.netrw_browsex_viewer = "xdg-open"

vim.g.python3_host_prog = "/usr/bin/python3"   -- use system python (useful when working with virualenvs)
vim.g.vga_compatible = vim.env.TERM == "linux" -- VGA textmode fallback (with CP437 character set) for legacy terminals

-- Automatic commands
-------------------------------------------------------------------------------
local au = require("au") -- small wrapper around lua autocmd api

-- start insert mode when opening a terminal
local open = au("user_open")
function open.TermOpen()
  vim.cmd("startinsert")
end

-- jump to last position when opening a file
function open.BufReadPost()
  local last_cursor_pos, last_line = vim.fn.line([['"]]), vim.fn.line("$")
  if last_cursor_pos > 1 and last_cursor_pos <= last_line then
    vim.fn.cursor(last_cursor_pos, 1)
  end
end

--[[
-- quickfix for https://github.com/neovim/neovim/issues/11330
function open.VimEnter()
  local pid, WINCH = vim.fn.getpid(), vim.loop.constants.SIGWINCH
  vim.defer_fn(function() vim.loop.kill(pid, WINCH) end, 20)
end
-]]

-- briefly highlight a selection on yank
local yank = au("user_yank")
function yank.TextYankPost()
  vim.highlight.on_yank()
end

-- automatically toggle between relative and absolute line numbers depending on mode
local number = au("user_number")
local relative = number{"BufEnter", "FocusGained", "InsertLeave", "TermLeave", "WinEnter"}
local absolute = number{"BufLeave", "FocusLost", "InsertEnter", "TermEnter", "WinLeave"}

function relative.handler()
  if vim.opt_local.number:get() and vim.fn.mode() ~= "i" then
    vim.opt_local.relativenumber = true
  end
end

function absolute.handler()
  if vim.opt_local.number:get() then
    vim.opt_local.relativenumber = false
  end
end

-- close preview window when completion is finished
local preview = au("user_preview")
function preview.CompleteDone()
  if vim.fn.pumvisible() == 0 then
    vim.cmd[[pclose]]
  end
end

-- restore view of current window when switching buffers
local view = au("user_view")
function view.BufWinLeave()
  vim.b.view = vim.fn.winsaveview()
end

function view.BufWinEnter()
  if vim.b.view then
    vim.fn.winrestview(vim.b.view)
    vim.b.view = nil
  end
end

-- Commands
-------------------------------------------------------------------------------
local cmd = vim.api.nvim_create_user_command

-- open (new) terminal at the bottom of the current tab
cmd("Terminal", function(tbl)
    require("term").open(#tbl.args > 0 and tbl.args or nil)
  end, {nargs = "?"}
)

cmd("Cd", "cd %:p:h", {})            -- set cwd to directory of current file
cmd("Run", '!"%:p"', {})             -- Execute current file
cmd("Config", "edit $MYVIMRC", {})   -- open config file with :Config
cmd("Reload", "source $MYVIMRC", {}) -- reload config file with :Reload

-- Mappings
-------------------------------------------------------------------------------
local map, opts = vim.keymap.set, {noremap = true, silent = true}

-- navigate buffers like tabs (gt & gT)
map("n", "<C-t>", ":tabnew ~/")
map("n", "<C-a>", "ggVG")
map("n", "<C-j>", "2j")
map("n", "<C-k>", "2k")
map("n", "<A-j>", ":m .+1<CR>")
map("n", "<A-k>", ":m .-2<CR>")
map("n", "<C-w>", ":q<CR>")
map("n", "<C-s>", ":w!<CR>")
map("n", "gb", function() vim.cmd("bnext" .. vim.v.count1) end, opts)
map("n", "gB", function() vim.cmd("bprev" .. vim.v.count1) end, opts)

-- diagnostics mappings
map("n", "<leader>ll", vim.diagnostic.setloclist, opts)
map("n", "<leader>ld", vim.diagnostic.open_float, opts)
map("n", "[d",         vim.diagnostic.goto_prev, opts)
map("n", "]d",         vim.diagnostic.goto_next, opts)

-- language server mappings
local function lsp_mappings(client, buf)
  local bufopts = {buffer = buf, unpack(opts)}
  map("n", "gd",         vim.lsp.buf.definition, bufopts)
  map("n", "gD",         vim.lsp.buf.declaration, bufopts)
  map("n", "<leader>gi", vim.lsp.buf.implementation, bufopts)
  map("n", "<leader>gt", vim.lsp.buf.type_definition, bufopts)
  map("n", "K",          vim.lsp.buf.hover, bufopts)
  -- map("n", "<C-k>",      vim.lsp.buf.signature_help, bufopts)
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
  map("n", "<leader>wl", function() vim.pretty_print(vim.lsp.buf.list_workspace_folders()) end, bufopts)
  map("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
  map("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
  map("n", "<leader>rf", vim.lsp.buf.references, bufopts)
  map("n", "<leader>fm", vim.lsp.buf.formatting, bufopts)
  map("v", "<leader>fm", ":lua vim.lsp.buf.range_formatting()<cr>", bufopts) -- return to normal mode

  if client.server_capabilities.documentRangeFormattingProvider then
    -- Use LSP as the handler for 'gq' mapping
    vim.api.nvim_buf_set_option(buf, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
  end
end

-- Diagnostics
-------------------------------------------------------------------------------
local prefix = "DiagnosticSign"

-- when not on the console set some nice signs
if not vim.g.vga_compatible then
  vim.fn.sign_define{
    {name = prefix .. "Error", text = "▌", texthl = prefix .. "Error"},
    {name = prefix .. "Warn",  text = "▌", texthl = prefix .. "Warn"},
    {name = prefix .. "Hint",  text = "▌", texthl = prefix .. "Hint"},
    {name = prefix .. "Info",  text = "▌", texthl = prefix .. "Info"}
  }
end

-- }}}
-------------------------------------------------------------------------------
-- {{{ Plugin-Specific Configuration
-------------------------------------------------------------------------------
require('plugins-old')

-- Gruvbox-Material
-------------------------------------------------------------------------------
--vim.g.gruvbox_contrast_dark = "hard"
--vim.g.gruvbox_italic = false
--vim.g.gruvbox_invert_selection = false
vim.g.gruvbox_material_disable_italic_comment = '0'
vim.g.gruvbox_material_background = 'hard'
vim.g.gruvbox_material_foreground = 'mix'
vim.g.gruvbox_material_visual = 'reverse' --'grey background'
vim.g.gruvbox_material_statusline_style = 'default' --'mix'
vim.g.gruvbox_material_better_performance = '1'

-- only enable this color scheme when supported by terminal
if not vim.g.vga_compatible then
  vim.cmd("colorscheme gruvbox-material")
end

-- Lualine
-------------------------------------------------------------------------------
local function getWords()
  return tostring(vim.fn.wordcount().words)
end

require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'gruvbox-material',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {},
    always_divide_middle = true,
    globalstatus = false,
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {}
}

-- Bufferline
-------------------------------------------------------------------------------
require('bufferline').setup {
  options = {
    mode = "tabs"
    }
  }

--IndentLine
require("indent_blankline").setup {
    -- for example, context is off by default, use this to turn it on
    show_current_context = true,
    show_current_context_start = true,
}
  -- Quick-Scope
-------------------------------------------------------------------------------
local quickscope = au("user_quickscope"){"ColorScheme", "VimEnter"}
vim.g.qs_highlight_on_keys = {"f", "F", "t", "T"}

function quickscope.handler()
  for group, color in pairs({QuickScopePrimary=10, QuickScopeSecondary=13}) do
    vim.api.nvim_set_hl(0, group, {
      sp = vim.g["terminal_color_" .. color],
      ctermfg = color,
      bold = true,
      underline = true
    })
  end
end

--[[ 
-- Gitsigns
-------------------------------------------------------------------------------
local gitsigns = require("gitsigns")

gitsigns.setup{
  signs = {
    add = {hl = "GitSignsAdd", text = vga_fallback("▌", "+")},
    change = {hl = "GitSignsChange", text = vga_fallback("▌", "≈")},
    delete = {hl = "GitSignsDelete", text = vga_fallback("▖", "v")},
    topdelete = {hl = "GitSignsDelete", text = vga_fallback("▘", "^")},
    changedelete = {hl = "GitSignsChange", text = vga_fallback("▌", "±")},
  },
  preview_config = {
    border = "none"
  },
  on_attach = function(buf)
    local bufopts = {buffer = buf, unpack(opts)}

    local function jump(direction)
      if vim.wo.diff then
        return ']c'
      end
      vim.schedule(direction)
      return '<Ignore>'
    end
    
    -- Navigation
    map("n", "]c", function() return jump(gitsigns.next_hunk) end, {expr = true, unpack(bufopts)})
    map("n", "[c", function() return jump(gitsigns.prev_hunk) end, {expr = true, unpack(bufopts)})

    -- Actions
    map({'n', 'v'}, '<leader>hr', ':Gitsigns reset_hunk<CR>', bufopts)
    map('n', '<leader>hp', gitsigns.preview_hunk, bufopts)

    -- highlight deleted lines in hunk previews in gitsigns.nvim
    vim.api.nvim_set_hl(0, "GitSignsDeleteLn", {link = "GitSignsDeleteVirtLn"})
  end
}

-- Colorizer
------------------------------------------------------------------------------
local colorizer = require("colorizer")

-- colorize color specifications like '#aabbcc' in virtualtext
colorizer.setup(
  {'*'},
  {names = false, mode = 'virtualtext'}
)

-- Lsp-config
-------------------------------------------------------------------------------
local lsputil = require('lspconfig.util')

-- setup calls to specific language servers are located in ftplugins
function lsputil.on_setup(config)
  config.on_attach = lsputil.add_hook_before(config.on_attach, lsp_mappings)
end

-- LuaSnip
-------------------------------------------------------------------------------
local luasnip = lazy_require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()

local function try_change_choice(direction)
  if luasnip.choice_active() then
    luasnip.change_choice(direction)
  end
end

-- we only define LuaSnip mappings for jumping around, expansion is handled by
-- insert mode completion (see help-page for 'ins-completion' and
-- 'completefunc' defined above).
map({"i", "s"}, "<C-s><C-n>", function() luasnip.jump(1) end, opts)
map({"i", "s"}, "<C-s><C-p>", function() luasnip.jump(-1) end, opts)
map({"i", "s"}, "<C-s><C-j>", function() try_change_choice(1) end, opts)
map({"i", "s"}, "<C-s><C-k>", function() try_change_choice(-1) end, opts)

-- Telescope
-------------------------------------------------------------------------------
local telescope = require("telescope")
local builtin = lazy_require("telescope.builtin")

telescope.load_extension('fzf')

-- when a count N is given to a telescope mapping called through the following
-- function, the search is started in the Nth parent directory
local function telescope_cwd(picker, args)
  builtin[picker](vim.tbl_extend("error", args or {}, {cwd = ("../"):rep(vim.v.count) .. "."}))
end

map("n", "<leader>ff", function() telescope_cwd('find_files', {hidden = true}) end, opts)
map("n", "<leader>lg", function() telescope_cwd('live_grep') end, opts)
map("n", "<leader>ws", function() builtin.lsp_dynamic_workspace_symbols() end, opts)
-]]

-- }}}
-- vim: foldmethod=marker foldmarker=--\ {{{,--\ }}}
