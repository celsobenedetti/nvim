return {
  work = {
    edge_server = os.getenv('EDGE_SERVER') or '',
    airflow_pipeline = os.getenv('AIRFLOW_PIPELINE') or '',
    io = '/home/celso/work/io',
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
