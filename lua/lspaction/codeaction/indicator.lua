local M = { servers = {} }
local _config = require("lspaction").config
local config = _config.code_action_prompt
local icon = _config.code_action_icon
local window = require "lspaction.codeaction.window"

local code_action = "textDocument/codeAction"

M.group = "sagalightbulb"
M.sign_name = "LspSagaLightBulb"

if vim.tbl_isempty(vim.fn.sign_getdefined(M.sign_name)) then
  vim.fn.sign_define(M.sign_name, { text = icon, texthl = "LspSagaLightBulbSign" })
end

M.require_diagnostics = {
  ["go"] = true,
  ["python"] = true,
}

M.special_buffers = {
  ["LspSagaCodeAction"] = true,
  ["lspsagafinder"] = true,
  ["NvimTree"] = true,
  ["vist"] = true,
  ["lspinfo"] = true,
  ["markdown"] = true,
  ["text"] = true,
}

local check_lsp_active = function()
  local active_clients = vim.lsp.get_active_clients()
  if next(active_clients) == nil then
    return false, "[lspaction] No lsp client available"
  end
  return true, nil
end

M.update = function(winid, line)
  if config.virtual_text then
    local namespace = vim.api.nvim_create_namespace "sagalightbulb"
    vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)

    if line then
      vim.api.nvim_buf_set_extmark(0, namespace, line, -1, {
        virt_text = { { "  " .. icon, M.sign_name } },
        virt_text_pos = "overlay",
        hl_mode = "combine",
      })
    end
  end

  if config.sign then
    if not window[winid] then
      return
    end

    if window[winid].lightbulb_line ~= 0 then
      vim.fn.sign_unplace(M.group, { id = window[winid].lightbulb_line, buffer = "%" })
    end

    if line and window[winid] then
      vim.fn.sign_place(line, M.group, M.sign_name, "%", {
        lnum = line + 1,
        priority = config.sign_priority,
      })
      window[winid].lightbulb_line = line
    end
  end
end

local function code_action_request(args)
  local bufnr = vim.api.nvim_get_current_buf()
  args.params.context = args.context or { diagnostics = vim.lsp.diagnostic.get_line_diagnostics() }
  local callback = args.callback { bufnr = bufnr, method = code_action, params = args.params }
  vim.lsp.buf_request_all(bufnr, code_action, args.params, callback)
end

M.check = function()
  local active, _ = check_lsp_active()
  local current_file = vim.fn.expand "%:p"

  if M.servers[current_file] == nil then
    local clients = vim.lsp.get_active_clients()
    for _, client in ipairs(clients) do
      if client.resolved_capabilities.code_action then
        M.servers[current_file] = true
        break
      end
    end
    if M.servers[current_file] == nil then
      M.servers[current_file] = false
    end
  end

  if M.special_buffers[vim.bo.filetype] or not active or M.servers[current_file] == false then
    return
  end

  local winid = vim.api.nvim_get_current_win()
  window[winid] = window[winid] or {}
  window[winid].lightbulb_line = window[winid].lightbulb_line or 0

  code_action_request {
    params = vim.lsp.util.make_range_params(),
    callback = function(ctx)
      local line = ctx.params.range.start.line
      local fail_to_have_diagnostics = M.require_diagnostics[vim.bo.filetype] and next(ctx.params.context.diagnostics) == nil
      local no_action = true

      return function(res)
        for _, result in pairs(res) do
          if result.result and next(result.result) ~= nil then
            no_action = false
            break
          end
        end

        if no_action or fail_to_have_diagnostics then
          return M.update(winid, nil)
        else
          return M.update(winid, line)
        end
      end
    end,
    winid = winid,
  }
end

M.attach = function()
  vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'lspaction.codeaction.indicator'.check()]]
end

return M