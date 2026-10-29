# language: fr
@api @US-104 @REQ-104
Fonctionnalité: Ligne de basse générée avec proposition d'accords

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:145 ; lyra-ml/app/main.py:1116 ; stratégie par défaut basse_et_accords.py:28
  @AC-1 @api
  Scénario: Sans stratégie précisée la basse est en walking
    Quand j'envoie POST "/api/generate/theme-accords-et-basse" avec le corps JSON :
      """
      {"generation_accords": {"tempo_bpm": 100, "mode": "dorien", "tonique": "Ré", "nombre_mesures": 4, "random_seed": 5}}
      """
    Alors la réponse a le statut 200
    Et la liste "accords" n'est pas vide
    Et la liste "basse" n'est pas vide
    Et le champ "bass_strategie" vaut "walking"

  # réf: lyra-api/generation/GenerationController.java:145 ; lyra-ml/app/main.py:1116 ; ValueError basse_et_accords.py:157
  @AC-2 @api
  Plan du Scénario: Progression et paramètres de génération fournis ensemble, ou aucun, sont refusés (<cas>)
    Quand j'envoie POST "/api/generate/theme-accords-et-basse" avec le corps JSON :
      """
      <corps>
      """
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée

    Exemples:
      | cas    | corps                                                                                                                  |
      | les deux | {"accords": "@fixture:accords-do-ionien.json", "generation_accords": {"tempo_bpm": 100, "nombre_mesures": 4}}          |
      | aucun  | {}                                                                                                                     |

  # réf: lyra-api/generation/GenerationController.java:145 ; lyra-ml/app/main.py:1116 ; basse_et_accords.py:173
  @AC-3 @api
  Scénario: Stratégie pédale sans tonique de pédale : la basse joue la tonique de la progression générée
    Quand j'envoie POST "/api/generate/theme-accords-et-basse" avec le corps JSON :
      """
      {"generation_accords": {"tempo_bpm": 100, "mode": "dorien", "tonique": "Ré", "nombre_mesures": 4, "random_seed": 5},
       "bass_strategie": "pedale"}
      """
    Alors la réponse a le statut 200
    Et le champ "bass_strategie" vaut "pedale"
    Et chaque élément de "basse" a "root_note" égal à "Ré"
