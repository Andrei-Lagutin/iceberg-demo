CREATE TABLE IF NOT EXISTS customers (
  customer_id   integer PRIMARY KEY,
  customer_name text NOT NULL,
  country       text
);

INSERT INTO customers (customer_id, customer_name, country) VALUES
  (1, 'Alice', 'NL'),
  (2, 'Bob',   'DE'),
  (3, 'Chloe', 'FR')
ON CONFLICT DO NOTHING;