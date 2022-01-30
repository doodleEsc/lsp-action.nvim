local wrap = require "lspaction.wrap"
local window = require "lspaction.codeaction.window"
local M = {}

local code_action = "textDocument/codeAction"

local check_lsp_active = function()
  local active_clients = vim.lsp.get_active_clients()
  if next(active_clients) == nil then
    return false, "[lspaction] No lsp client available"
  end
  return true, nil
end

local function code_action_request(args)
  local bufnr = vim.api.nvim_get_current_buf()
  args.params.context = args.context or { diagnostics = vim.lsp.diagnostic.get_line_diagnostics() }
  local callback = args.callback { bufnr = bufnr, method = code_action, params = args.params }
  vim.lsp.buf_request_all(bufnr, code_action, args.params, callback)
end

local on_code_action_response = function(ctx)
  window.bufnr = vim.fn.bufnr()
  window.ctx = ctx
  window.content, window.actions = { window.title }, {}

  return function(response)
    for client_id, result in pairs(response or {}) do
      for index, action in ipairs(result.result or {}) do
        table.insert(window.actions, { client_id, action })
        table.insert(window.content, "[" .. index .. "]" .. " " .. action.title)
      end
    end

    if #window.actions == 0 or #window.content == 1 then
      vim.notify("No code actions available", vim.log.levels.INFO)
      return
    end

    table.insert(window.content, 2, wrap.add_truncate_line(window.content))

    window.open {
      contents = window.content,
      filetype = "LspSagaCodeAction",
      enter = true,
      highlight = "LspSagaCodeActionBorder",
    }
  end
end

M.range_code_action = function(context, start_pos, end_pos)
  local active, msg = check_lsp_active()
  if not active then
    print(msg)
    return
  end
  code_action_request {
    params = vim.lsp.util.make_given_range_params(start_pos, end_pos),
    context = context,
    callback = on_code_action_response,
  }
end

M.code_action = function()
  local active, _ = check_lsp_active()
  if not active then
    return
  end
  code_action_request {
    params = vim.lsp.util.make_range_params(),
    callback = on_code_action_response,
  }
end

return M
