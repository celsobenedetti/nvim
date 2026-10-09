--- @alias Agents
--- | 'claude'
--- | 'opencode'
--- | 'pi'

---@class AgentsState
---@field bufnr table<Agents, number>
local M = {
  bufnr = {},
}
M.get_agent_bufnr = function(agent)
  return M.bufnr[agent] or 0
end
M.set_agent_bufnr = function(agent, bufnr)
  M.bufnr[agent] = bufnr
end
M.is_active = function(agent)
  return M.get_agent_bufnr(agent) > 0
end
state.agents = M

--- @param key string keymap
--- @param agent Agents agent cli cmd
local function setup_agent(key, agent)
  M.set_agent_bufnr(agent, 0)

  local function new_agent()
    vim.cmd.term('caveman ' .. agent)
    M.set_agent_bufnr(agent, vim.api.nvim_get_current_buf())
  end

  vim.api.nvim_create_autocmd('TermClose', {
    desc = agent .. ': close terminal buffer when ' .. agent .. ' exits',
    callback = function(args)
      if args.buf ~= M.get_agent_bufnr(agent) then
        return
      end
      M.set_agent_bufnr(agent, 0)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(args.buf) then
          vim.api.nvim_buf_delete(args.buf, { force = true })
        end
      end)
    end,
  })

  local command = agent:gsub('^%l', string.upper)
  vim.api.nvim_create_user_command(command, new_agent, { desc = 'Open or focus the ' .. agent .. ' terminal' })
  vim.keymap.set('n', key, string.format(':%s<CR>', command), { desc = agent .. ': open/focus terminal' })
end

for _, agent in ipairs(config.agents) do
  setup_agent(agent.key, agent.cmd)
end
