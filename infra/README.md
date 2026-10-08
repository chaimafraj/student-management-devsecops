# Infrastructure de supervision et de qualité (laboratoire local)

VM Ubuntu gérée par Vagrant (provider VMware) hébergeant :

| Service | Port | Rôle |
|---|---|---|
| SonarQube | 9000 | Centralisation des résultats d'analyse de code |
| Grafana | 3000 | Tableaux de bord |
| Prometheus | 9090 | Collecte de métriques |
| cAdvisor | 8088 | Métriques des conteneurs |
| node-exporter | interne | Métriques de la VM |
| Portainer | 9443 (HTTPS) | Administration Docker |

## Démarrage
1. `bash scripts/prepare-vm.sh`
2. `cd sonarqube && docker compose up -d`
3. `cd ../monitoring && cp .env.example .env` (modifier le mot de passe), puis `docker compose up -d`

## Sécurité
Environnement de laboratoire, non exposé. Portainer monte le socket Docker (droits équivalents à root sur la VM) :
risque accepté et documenté, d'où l'exclusion du dossier `infra/` du scan Semgrep (voir `.semgrepignore`).
Les mots de passe sont dans des fichiers `.env` non versionnés.
