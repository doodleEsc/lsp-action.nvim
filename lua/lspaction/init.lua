local lspaction = {}

lspaction.config = {
	error_sign = "",
	warn_sign = "",
	hint_sign = "",
	infor_sign = "",
	code_action_icon = " ",
	code_action_prompt = {
		enable = true,
		sign = true,
		sign_priority = 50,
		virtual_text = true,
	},
	code_action_keys = {
		quit = "<C-c>",
		exec = "<CR>",
	},
	border_style = "single",
	rename_prompt_prefix = "➤",
	rename_prompt_populate = true,
	rename_action_keys = {
		quit = "<C-c>",
		exec = "<CR>",
	},
}

local extend_config = function(opts)
  opts = opts or {}
  if next(opts) == nil then
    return
  end
  for key, value in pairs(opts) do
    if lspaction.config[key] == nil then
      error(string.format("[lspaction] Key %s not exist in config values", key))
      return
    end
    if type(lspaction.config[key]) == "table" then
      for k, v in pairs(value) do
        lspaction.config[key][k] = v
      end
    else
      lspaction.config[key] = value
    end
  end
end

lspaction.setup = function(opts)
	extend_config(opts)
	local config = lspaction.config

	for type, icon in pairs {
	  Error = config.error_sign,
	  Warn = config.warn_sign,
	  Hint = config.hint_sign,
	  Info = config.infor_sign,
	} do
	  local hl = "DiagnosticSign" .. type
	  vim.fn.sign_define(hl, {
		text = icon,
		texthl = hl,
		numhl = "",
	  })
	end

	if config.code_action_prompt.enable then
		require("lspaction.codeaction.indicator").attach()
	end

end

return lspaction
