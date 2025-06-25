#!/bin/bash
set -e

echo "🔧 Initialisation PostgreSQL..."

# 1. Démarrer PostgreSQL
sudo -u postgres pg_ctlcluster 15 main start || echo "Cluster already running."

# 2. Créer les bases si elles n'existent pas
for DB in raw dbt_training_dev dbt_training_prod; do
  sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '$DB'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE $DB;"
done

# 3. Créer l'utilisateur dbt_user s'il n'existe pas
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = 'dbt_user'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER dbt_user WITH PASSWORD 'strong_password';"

# 4. Donner les droits à dbt_user sur les bases et schémas
for DB in raw dbt_training_dev dbt_training_prod; do
  sudo -u postgres psql -d "$DB" -c "GRANT ALL PRIVILEGES ON DATABASE $DB TO dbt_user;"
  sudo -u postgres psql -d "$DB" -c "GRANT ALL ON SCHEMA public TO dbt_user;"
done

# 4.b Droits de lecture sur jaffle_shop et stripe + search_path
for SCHEMA in jaffle_shop stripe; do
  sudo -u postgres psql -d raw -tc "SELECT 1 FROM pg_namespace WHERE nspname = '$SCHEMA'" | grep -q 1 || \
    sudo -u postgres psql -d raw -c "CREATE SCHEMA $SCHEMA;"
  sudo -u postgres psql -d raw -c "GRANT USAGE ON SCHEMA $SCHEMA TO dbt_user;"
  sudo -u postgres psql -d raw -c "GRANT SELECT ON ALL TABLES IN SCHEMA $SCHEMA TO dbt_user;"
done
sudo -u postgres psql -c "ALTER ROLE dbt_user SET search_path TO public, jaffle_shop, stripe;"

# 5. Créer les tables dans la base raw
sudo -u postgres psql -d raw <<'EOF'
CREATE TABLE IF NOT EXISTS jaffle_shop.customers (
  id INTEGER,
  first_name VARCHAR,
  last_name VARCHAR
);

CREATE TABLE IF NOT EXISTS jaffle_shop.orders (
  id INTEGER,
  user_id INTEGER,
  order_date DATE,
  status VARCHAR,
  _etl_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stripe.payment (
  id INTEGER,
  orderid INTEGER,
  paymentmethod VARCHAR,
  status VARCHAR,
  amount INTEGER,
  created DATE,
  _batched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# 6. Télécharger les fichiers
mkdir -p /tmp/jaffle_data
curl -s -o /tmp/jaffle_data/jaffle_shop_customers.csv https://dbt-tutorial-public.s3.amazonaws.com/jaffle_shop_customers.csv
curl -s -o /tmp/jaffle_data/jaffle_shop_orders.csv https://dbt-tutorial-public.s3.amazonaws.com/jaffle_shop_orders.csv
curl -s -o /tmp/jaffle_data/stripe_payments.csv https://dbt-tutorial-public.s3.amazonaws.com/stripe_payments.csv

# 7. Insérer les données
echo "📤 Chargement des données..."
sudo -u postgres psql -d raw -c "\COPY jaffle_shop.customers FROM '/tmp/jaffle_data/jaffle_shop_customers.csv' CSV HEADER;"
sudo -u postgres psql -d raw -c "\COPY jaffle_shop.orders(id, user_id, order_date, status) FROM '/tmp/jaffle_data/jaffle_shop_orders.csv' CSV HEADER;"
sudo -u postgres psql -d raw -c "\COPY stripe.payment(id, orderid, paymentmethod, status, amount, created) FROM '/tmp/jaffle_data/stripe_payments.csv' CSV HEADER;"

echo "✅ Bases initialisées avec succès."
