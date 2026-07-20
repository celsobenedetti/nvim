return {
  work = {
    edge_server = os.getenv('EDGE_SERVER') or '',
    airflow_pipeline = os.getenv('AIRFLOW_PIPELINE') or '',
    io = '/home/celso/work/io',
  },
}
