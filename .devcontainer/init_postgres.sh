#!/bin/bash
set -e

echo "? Initialisation PostgreSQL..."

# 1. Demarrer PostgreSQL
sudo -u postgres pg_ctlcluster 15 main start || echo "Cluster already running."

# 2. Creer les bases si elles n'existent pas (uniquement dev + prod)
for DB in dbt_training_dev dbt_training_prod; do
  sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '$DB'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE $DB;"
done

# 3. Creer l'utilisateur dbt_user s'il n'existe pas
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = 'dbt_user'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER dbt_user WITH PASSWORD 'strong_password';"

# 4. Donner les droits a dbt_user sur les bases dev et prod
for DB in dbt_training_dev dbt_training_prod; do
  sudo -u postgres psql -d "$DB" -c "GRANT ALL PRIVILEGES ON DATABASE $DB TO dbt_user;"
  sudo -u postgres psql -d "$DB" -c "GRANT ALL ON SCHEMA public TO dbt_user;"
done

# 5. Creer les schemas jaffle_shop et stripe dans dbt_training_dev (prefixe par raw_)
for SCHEMA in raw_jaffle_shop raw_stripe; do
  sudo -u postgres psql -d dbt_training_dev -tc "SELECT 1 FROM pg_namespace WHERE nspname = '$SCHEMA'" | grep -q 1 || \
    sudo -u postgres psql -d dbt_training_dev -c "CREATE SCHEMA $SCHEMA;"
done


# 6. Creer les tables dans raw_jaffle_shop et raw_stripe dans dbt_training_dev
sudo -u postgres psql -d dbt_training_dev <<'EOF'
CREATE TABLE IF NOT EXISTS raw_jaffle_shop.customers (
  id INTEGER,
  first_name VARCHAR,
  last_name VARCHAR
);

CREATE TABLE IF NOT EXISTS raw_jaffle_shop.orders (
  id INTEGER,
  user_id INTEGER,
  order_date DATE,
  status VARCHAR,
  _etl_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS raw_stripe.payment (
  id INTEGER,
  orderid INTEGER,
  paymentmethod VARCHAR,
  status VARCHAR,
  amount INTEGER,
  created DATE,
  _batched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# 7. Telecharger les fichiers CSV
mkdir -p /tmp/jaffle_data
curl -s -o /tmp/jaffle_data/jaffle_shop_customers.csv https://dbt-tutorial-public.s3.amazonaws.com/jaffle_shop_customers.csv
curl -s -o /tmp/jaffle_data/jaffle_shop_orders.csv https://dbt-tutorial-public.s3.amazonaws.com/jaffle_shop_orders.csv
curl -s -o /tmp/jaffle_data/stripe_payments.csv https://dbt-tutorial-public.s3.amazonaws.com/stripe_payments.csv

# 8. Inserer les donnees
echo "? Chargement des donnees..."
sudo -u postgres psql -d dbt_training_dev -c "\COPY raw_jaffle_shop.customers FROM '/tmp/jaffle_data/jaffle_shop_customers.csv' CSV HEADER;"
sudo -u postgres psql -d dbt_training_dev -c "\COPY raw_jaffle_shop.orders(id, user_id, order_date, status) FROM '/tmp/jaffle_data/jaffle_shop_orders.csv' CSV HEADER;"
sudo -u postgres psql -d dbt_training_dev -c "\COPY raw_stripe.payment(id, orderid, paymentmethod, status, amount, created) FROM '/tmp/jaffle_data/stripe_payments.csv' CSV HEADER;"

# 9. Droits pour dbt_user sur les schemas et tables
for SCHEMA in raw_jaffle_shop raw_stripe; do
  sudo -u postgres psql -d dbt_training_dev -c "GRANT USAGE ON SCHEMA $SCHEMA TO dbt_user;"
  sudo -u postgres psql -d dbt_training_dev -c "GRANT SELECT ON ALL TABLES IN SCHEMA $SCHEMA TO dbt_user;"
done

# 10. Definir le search_path par defaut
sudo -u postgres psql -c "ALTER ROLE dbt_user SET search_path TO public, raw_jaffle_shop, raw_stripe;"

echo "? Initialisation terminee avec succes."
