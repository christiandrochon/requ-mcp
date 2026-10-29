# language: fr
@api @US-102 @REQ-102
Fonctionnalité: Progression d'accords évolutive avec courbe de tension et climax

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:69 ; lyra-ml/app/main.py:1031 ; constraints_applied.niveau_tension : chord_progression.py:798,836,879,925,977
  @AC-1 @api
  Scénario: Chaque décision porte le niveau de tension cible de sa position
    Quand j'envoie POST "/api/generate/progression-avec-tension" avec le corps JSON :
      """
      {"tempo_bpm": 100, "mode": "dorien", "tonique": "Ré", "nombre_mesures": 8, "metrique": "4/4",
       "indice_climax": 4, "tension_minimale": 0.1, "tension_climax": 0.9, "random_seed": 3}
      """
    Alors la réponse a le statut 200
    Et la liste "result.decisions" n'est pas vide
    Et chaque élément de "result.decisions" a un champ numérique "constraints_applied.niveau_tension"

  # réf: lyra-api/generation/GenerationController.java:69 ; lyra-ml/app/main.py:1031
  @AC-2 @api
  Plan du Scénario: Premier et dernier accords sont la tonique non empruntée (graine <graine>)
    Quand j'envoie POST "/api/generate/progression-avec-tension" avec le corps JSON :
      """
      {"tempo_bpm": 100, "mode": "dorien", "tonique": "Ré", "nombre_mesures": 8,
       "indice_climax": 4, "tension_minimale": 0.1, "tension_climax": 0.9, "autoriser_emprunts": true, "random_seed": <graine>}
      """
    Alors la réponse a le statut 200
    Et le champ "result.accords[0].degree_index" vaut 0
    Et le champ "result.accords[-1].degree_index" vaut 0
    Et le champ "result.accords[0].est_emprunt" vaut false
    Et le champ "result.accords[-1].est_emprunt" vaut false

    Exemples:
      | graine |
      | 1      |
      | 2      |
      | 3      |
      | 4      |

  # réf: lyra-api/generation/GenerationController.java:69 ; lyra-ml/app/main.py:1031 ; validateur Pydantic nombre_mesures<=0 : chord_progression.py:187 ; tension_climax<=tension_minimale : chord_progression.py:248 (ValueError dans la fonction)
  @AC-3 @api
  Plan du Scénario: Une courbe de tension ou un nombre de mesures invalide est refusé (<cas>)
    Quand j'envoie POST "/api/generate/progression-avec-tension" avec le corps JSON :
      """
      {"tempo_bpm": 100, "mode": "dorien", "tonique": "Ré", "nombre_mesures": <mesures>,
       "indice_climax": 2, "tension_minimale": <min>, "tension_climax": <climax>}
      """
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée

    Exemples:
      | cas                         | mesures | min | climax |
      | climax égal au minimum      | 8       | 0.5 | 0.5    |
      | climax inférieur au minimum | 8       | 0.6 | 0.2    |
      | nombre de mesures nul       | 0       | 0.1 | 0.9    |
      | nombre de mesures négatif   | -2      | 0.1 | 0.9    |
