# Lister les projets suivis par requ

Pour savoir quels projets requ suit, et ce que chacun contient.

requ tourne dans deux conteneurs Docker :

| Conteneur | Rôle | Port sur la machine |
|---|---|---|
| `requ-mcp-http` | serveur requ (MCP et API web) | 8788 |
| `requ-mcp-pg` | base PostgreSQL où vivent tous les projets | 5433 |

Les projets n'ont pas de fichier sur le disque. Ils sont stockés dans la base, dans le volume Docker `requ-mcp_pgdata`. Chaque ligne de chaque table porte un `project_id` (par exemple `lyra`). La table `config` contient la fiche de chaque projet : nom, clé, phase active, version, chemin des tests.

## 0. Vérifier que requ tourne

```bash
docker ps --filter name=requ-mcp --format '{{.Names}}\t{{.Status}}'
```

Affiche les deux conteneurs et leur état. Les deux doivent être `Up … (healthy)`.

```bash
curl -s localhost:8788/api/version
```

Renvoie la version du serveur, par exemple `{"version":"2.3.3"}`. Sans réponse, le serveur est arrêté.

## 1. Lister les projets

### Par l'API web (le plus simple)

```bash
curl -s localhost:8788/api/projects | jq
```

Liste les projets chargés par le serveur : `slug` (identifiant utilisé dans les URL), `key` (clé courte, ex. `LYRA`), `name` et `root` (chemin interne au conteneur, pas un dossier de ta machine). Sans `jq`, retire `| jq` : le résultat reste lisible, sur une seule ligne.

### Directement dans la base

```bash
docker exec requ-mcp-pg sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "select project_id, value::jsonb->>'"'"'key'"'"' as cle, value::jsonb->>'"'"'name'"'"' as nom from config where key = '"'"'config'"'"' order by 1"'
```

Lit la table `config` et affiche un projet par ligne. Cette commande fonctionne même si le serveur `requ-mcp-http` est arrêté. Les `'"'"'` servent uniquement à faire passer les apostrophes à travers `sh -c`.

### Depuis Claude

Demander « liste les projets requ » : Claude appelle l'outil MCP `list_projects`, qui renvoie la même liste que `/api/projects`.

## 2. Voir un projet en détail

Dans les commandes suivantes, remplacer `lyra` par le `slug` du projet voulu.

```bash
curl -s "localhost:8788/api/config?project=lyra" | jq 'del(.brief)'
```

Affiche la fiche du projet sans sa description (`brief`), trop longue : clé, phase active, version, dossier des tests Conductor (`conductorPath`) et rapport d'exécution par défaut.

```bash
curl -s "localhost:8788/api/summary?project=lyra" | jq '{requirements, stories, scenariosTotal, adrs}'
```

Donne les volumes du projet : nombre d'exigences, de stories, de scénarios et d'ADR. Sans le filtre `jq`, le résumé affiche aussi le détail par phase, avec les pourcentages de couverture.

## 3. Explorer la base à la main

```bash
docker exec -it requ-mcp-pg sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

Ouvre une session `psql` interactive dans la base de requ. Une fois dedans :

| Commande | Effet |
|---|---|
| `\dt` | liste les tables |
| `select project_id, key from config;` | liste les fiches de projet |
| `select project_id, count(*) from requirements group by 1;` | nombre de lignes d'exigences par projet |
| `\q` | quitte |

Rester en lecture seule (`select`) : les données se modifient par les outils requ, pas en SQL direct.

## Interface web

<http://localhost:8788> affiche les mêmes informations dans le navigateur.
