local M = {}

-- Store lf state per buffer
local lf_state = {}

-- Default configuration
M.config = {
  width = 0.8,
  height = 0.9,
  title = "Lf",
  opener = "edit",
  lf_command = "set mouse;map e open;map l open;map o ${{open $f}};set sortby name;set noreverse",
  -- Terminal behavior
  auto_insert = true,
  start_insert = true,
  position = "float",
  -- Keybindings for opening files in different modes
  maps = {
    ["<C-t>"] = "tabedit",
    ["<C-s>"] = "split",
    ["<C-v>"] = "vsplit",
  },
  -- Whether to cleanup buffers for renamed files
  cleanup_renamed = true,
  -- Key to send on resize (default: Ctrl-L, set to "" to disable)
  resize_key = "\x0c",
}

local function augroup(name)
  return vim.api.nvim_create_augroup("snacks_lf_" .. name, { clear = true })
end

---@class snacks-lf.Config
---@field path? string Path to open in lf (defaults to current file or cwd)
---@field opener? string Default opener mode ("edit", "split", "vsplit", "tabedit")
---@field width? number Float window width (0-1 for percentage, >1 for columns)
---@field height? number Float window height (0-1 for percentage, >1 for rows)
---@field title? string Terminal window title
---@field lf_command? string Custom lf command options
---@field auto_insert? boolean Start insert mode when entering terminal
---@field start_insert? boolean Start insert mode when terminal starts
---@field position? string Terminal position ("float", "bottom", "top", "left", "right")
---@field maps? table<string, string> Keybindings for opening files (e.g., {["<C-t>"] = "tabedit"})
---@field cleanup_renamed? boolean Whether to cleanup buffers for renamed files
---@field resize_key? string Key to send on resize (default: "\x0c" for Ctrl-L, empty string to disable)
---@field env? table<string, string> Environment variables to pass to terminal (TERM auto-added)

--- Setup function for lazy.nvim
---@param opts? snacks-lf.Config User configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

--- Open lf file manager in a snacks terminal
---@param opts? snacks-lf.Config Options for lf integration
function M.open(opts)
  -- Merge with config defaults
  opts = vim.tbl_deep_extend("force", M.config, opts or {})

  local fn = opts.path or vim.fn.expand("%:p")
  -- if file doesn't exist, open directory
  if vim.fn.filereadable(fn) == 0 then
    fn = vim.g.project_path or vim.getcwd()
  end

  -- Create temp file for lf selection
  local tmpfile = vim.fn.tempname()

  local lf_cmd = string.format(
    "lf -selection-path='%s' -command '%s' '%s'",
    tmpfile,
    opts.lf_command,
    fn
  )

  -- Set up environment variables for terminal
  local env = opts.env or {}
  env.LF_NVIM_TERMINAL = "1" -- Signal to preview script that we're in Neovim
  if vim.env.TERM and not env.TERM then
    env.TERM = vim.env.TERM
  end

  local term = Snacks.terminal.toggle(lf_cmd, {
    auto_insert = opts.auto_insert,
    start_insert = opts.start_insert,
    auto_close = false, -- We handle closing ourselves after file selection
    env = env,
    win = {
      style = "lazygit",
      position = opts.position,
      width = opts.width,
      height = opts.height,
      title = opts.title,
      title_pos = "left",
      on_buf = function(self)
        -- Initialize lf state for this buffer
        lf_state[self.buf] = {
          tmpfile = tmpfile,
          opener = opts.opener,
        }

        -- Setup keybindings for different open modes
        for key, opener in pairs(opts.maps) do
          vim.keymap.set("t", key, function()
            lf_state[self.buf].opener = opener
            -- Feed 'l' to trigger lf's open action (quit lf with selection)
            vim.api.nvim_feedkeys("l", "i", false)
          end, { buffer = self.buf, desc = "Open in " .. opener })
        end

        -- Handle file opening when lf closes
        vim.api.nvim_create_autocmd("TermClose", {
          buffer = self.buf,
          group = augroup("open_files"),
          once = true,
          callback = function()
            local buf = self.buf
            local state = lf_state[buf]
            if not state then
              return
            end

            vim.schedule(function()
              if vim.fn.filereadable(state.tmpfile) == 1 then
                local filenames = vim.fn.readfile(state.tmpfile)
                if #filenames > 0 then
                  -- Hide terminal before opening files
                  if self:win_valid() then
                    self:hide()
                  end

                  -- Open files according to opener mode
                  for i, filename in ipairs(filenames) do
                    local fullpath = vim.fn.fnamemodify(filename, ":p")
                    if i == 1 then
                      vim.cmd(state.opener .. " " .. vim.fn.fnameescape(fullpath))
                    else
                      -- For subsequent files, always use the same split type
                      vim.cmd(state.opener .. " " .. vim.fn.fnameescape(fullpath))
                    end
                  end
                end
              end

              -- Always close terminal after lf exits
              if self:buf_valid() then
                self:close()
              end

              -- Cleanup temp file
              vim.fn.delete(state.tmpfile)
              if buf then
                lf_state[buf] = nil
              end
            end)
          end,
        })

        -- Remove old buffer if renamed in lf
        if opts.cleanup_renamed then
          vim.api.nvim_create_autocmd("TermLeave", {
            buffer = self.buf,
            group = augroup("rename"),
            once = true, -- Only run once per terminal session
            callback = function()
              vim.schedule(function()
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                  local bufname = vim.api.nvim_buf_get_name(buf)
                  if
                    not vim.bo[buf].readonly
                    and bufname ~= ""
                    and vim.fn.filereadable(bufname) ~= 1
                  then
                    local success, msg = pcall(vim.api.nvim_buf_delete, buf, { force = true })
                    if not success then
                      vim.notify("Error deleting buffer: " .. msg, vim.log.levels.WARN)
                    end
                  end
                end
              end)
            end,
          })
        end

        -- Handle terminal resize
        if opts.resize_key and opts.resize_key ~= "" then
          vim.api.nvim_create_autocmd("VimResized", {
            buffer = self.buf,
            group = augroup("resize_" .. self.buf),
            callback = function()
              vim.schedule(function()
                if self:buf_valid() and self:win_valid() then
                  -- Send configured key to trigger recalculation
                  vim.api.nvim_chan_send(vim.bo[self.buf].channel, opts.resize_key)
                end
              end)
            end,
          })
        end
      end,
    },
  })

  return term
end

--- Toggle lf file manager
---@param opts? snacks-lf.Config Options for lf integration (same as M.open)
function M.toggle(opts)
  return M.open(opts)
end

return M
