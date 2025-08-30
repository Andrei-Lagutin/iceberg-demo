from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator
import trino

DAG_ID = "trino_iceberg_demo"

def run_trino_sql(sql: str):
    conn = trino.dbapi.connect(
        host="trino", port=8080, user="airflow", http_scheme="http"
    )
    cur = conn.cursor()
    cur.execute(sql)
    try:
        rows = cur.fetchall()
        print("Rows:", rows[:10])
    except Exception:
        pass

with DAG(
    DAG_ID,
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo","trino","iceberg"],
) as dag:

    create_schema = PythonOperator(
        task_id="create_schema",
        python_callable=run_trino_sql,
        op_kwargs={"sql": "CREATE SCHEMA IF NOT EXISTS iceberg.demo"},
    )

    create_orders = PythonOperator(
        task_id="create_orders",
        python_callable=run_trino_sql,
        op_kwargs={
            "sql": """
            CREATE TABLE IF NOT EXISTS iceberg.demo.orders (
              order_id     integer,
              customer_id  integer,
              amount       double,
              ts           timestamp
            )
            """
        },
    )

    seed_orders = PythonOperator(
        task_id="seed_orders",
        python_callable=run_trino_sql,
        op_kwargs={
            "sql": """
            INSERT INTO iceberg.demo.orders (order_id, customer_id, amount, ts)
            VALUES
              (101, 1, 120.50, current_timestamp),
              (102, 2,  75.00, current_timestamp),
              (103, 1,  33.30, current_timestamp)
            """
        },
    )

    ctas_customer_orders = PythonOperator(
        task_id="ctas_customer_orders",
        python_callable=run_trino_sql,
        op_kwargs={
            "sql": """
            CREATE TABLE IF NOT EXISTS iceberg.demo.customer_orders AS
            SELECT
              o.order_id,
              o.customer_id,
              c.customer_name,
              c.country,
              o.amount,
              o.ts
            FROM iceberg.demo.orders o
            JOIN postgres.public.customers c
              ON o.customer_id = c.customer_id
            """
        },
    )

    list_join = PythonOperator(
        task_id="select_join_preview",
        python_callable=run_trino_sql,
        op_kwargs={
            "sql": """
            SELECT o.order_id, c.customer_name, o.amount, c.country
            FROM iceberg.demo.orders o
            JOIN postgres.public.customers c
              ON o.customer_id = c.customer_id
            ORDER BY o.order_id
            """
        },
    )

    create_schema >> create_orders >> seed_orders >> ctas_customer_orders >> list_join
