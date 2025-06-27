## 🐳 Dev Container intégré

Ce projet inclut un **Dev Container** prêt à l’emploi pour simplifier le setup de l’environnement de développement de la formation dbt.

### Fonction du Dev Container

Un *Dev Container* est un environnement de développement défini dans un fichier `devcontainer.json`, utilisé avec **Visual Studio Code** et **Docker**.  
Il permet de coder dans un conteneur isolé, avec tous les outils et dépendances déjà installés.

---

### Ce que fait le Dev Container dans ce repo

Lors du démarrage :

1. Il installe :
   - Python 3.11
   - PostgreSQL 15 (client + serveur)
   - `dbt-postgres`
   - Extensions utiles de VS Code (YAML, dbt, SQLFluff, PostgreSQL, etc.)

2. Il initialise PostgreSQL automatiquement via un script `.devcontainer/init_postgres.sh` :
   - Création des bases `dbt_training_dev` et `dbt_training_prod`
   - Création de l’utilisateur `dbt_user`
   - Création des schémas `raw_jaffle_shop` et `raw_stripe`
   - Insertion de données depuis depuis un bucket S3

3. Il expose PostgreSQL sur le port `5432`.

---

### Extension PostgreSQL

L’extension **PostgreSQL de VSCode** est préinstallée dans le container afin visualiser les bases, schémas et tables sans configuration supplémentaire.


---

### Démarrer le projet

S'assurer d’avoir **Docker** et **VS Code** installés, puis :

1. Ouvrir le repo dans VS Code
2. Cliquer sur `Reopen in Container` (ou `Dev Containers: Reopen in Container` dans la palette de commande)
3. Patienter quelques minutes pendant l’installation automatique

---
### Connexion à PostgreSQL via l’extension VS Code

Pour se connecter :

1. Ouvrir le panneau **PostgreSQL** dans la barre latérale de VS Code (icône base de données)
2. Cliquer sur **"Ajouter une nouvelle connexion"**
3. Renseigner les informations suivantes :

| Champ            | Valeur                 |
|------------------|------------------------|
| **Hôte**         | `localhost`            |
| **Port**         | `5432`                 |
| **Utilisateur**  | `dbt_user`             |
| **Mot de passe** | `strong_password`      |
| **Base**         | `dbt_training_dev`     |

4. Cliquer sur **Connecter**

Vous pouvez ensuite explorer les schémas et tables directement dans l’interface VS Code.

> Les schémas de données sources sont `raw_jaffle_shop` et `raw_stripe`.

---


L’environnement est prêt !

---
