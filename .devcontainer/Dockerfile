FROM mcr.microsoft.com/devcontainers/python:3.11

ARG USERNAME=vscode

# Installer PostgreSQL serveur et client
RUN apt-get update && apt-get install -y \
    postgresql-15 postgresql-client-15 postgresql-contrib-15 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

 # Configurer PostgreSQL pour autoriser les connexions extérieures
RUN echo "listen_addresses = '*'" >> /etc/postgresql/15/main/postgresql.conf && \
    echo "host all all all md5" >> /etc/postgresql/15/main/pg_hba.conf

# Installer dbt-postgres
RUN pip install --no-cache-dir dbt-postgres

# Créer un répertoire .dbt pour les profils
RUN mkdir -p /workspace/.dbt && chown -R $USERNAME:$USERNAME /workspace/.dbt

# Désactiver le mot de passe sudo pour l'utilisateur vscode
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd

USER $USERNAME
WORKDIR /workspace
