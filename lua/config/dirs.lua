return {
  work = {
    edge_server = vim.g.env.WORK .. '/integrations-private',
    airflow_pipeline = vim.g.env.WORK .. '/gva-etl-airflow-dags-pipeline',
  },
  dont_format = {
    '.local/share/nvim/lazy', -- ~/.local/share/nvim/lazy
  },
  format_with_eslint = {
    'ecommerce',
  },
  disable_eslint_lsp = {
    'integrations',
  },
}
