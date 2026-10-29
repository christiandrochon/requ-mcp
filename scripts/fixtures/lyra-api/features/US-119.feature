# language: fr
@api @US-119 @REQ-119
Fonctionnalité: Batterie depuis rien en métrique arbitraire avec patrons nommés

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:108 ; lyra-ml/app/main.py:1076 lyra-api/generation/GenerationController.java:120 ; lyra-ml/app/main.py:1089 lyra-api/generation/GenerationController.java:132 ; lyra-ml/app/main.py:1102 ; groove.py:518,570,675
  @AC-1 @api
  Scénario: Double pédale, blast beat et breakdown ternaire acceptés en 7/8
    Quand j'envoie POST "/api/generate/patron-double-pedale" avec le corps JSON :
      """
      {"nombre_mesures": 2, "metrique": "7/8"}
      """
    Alors la réponse a le statut 200
    Et la liste "hits" n'est pas vide
    Quand j'envoie POST "/api/generate/blast-beat" avec le corps JSON :
      """
      {"nombre_mesures": 2, "style": "traditionnel", "metrique": "7/8"}
      """
    Alors la réponse a le statut 200
    Et la liste "hits" n'est pas vide
    Quand j'envoie POST "/api/generate/breakdown" avec le corps JSON :
      """
      {"nombre_mesures": 2, "style": "ternaire_triplet_feel", "metrique": "7/8"}
      """
    Alors la réponse a le statut 200
    Et la liste "hits" n'est pas vide

  # réf: lyra-api/generation/GenerationController.java:132 ; lyra-ml/app/main.py:1102 ; groove.py:705-710
  @AC-2 @api
  Scénario: Un breakdown binaire_half_time hors 4/4 est refusé
    Quand j'envoie POST "/api/generate/breakdown" avec le corps JSON :
      """
      {"nombre_mesures": 2, "style": "binaire_half_time", "metrique": "7/8"}
      """
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée

  # réf: lyra-api/generation/GenerationController.java:108 ; lyra-ml/app/main.py:1076 ; défaut metrique "4/4" (groove.py:518)
  @AC-3 @api
  Plan du Scénario: Sans métrique explicite le résultat est celui du 4/4 explicite (<patron>)
    Quand j'envoie POST "<route>" avec le corps JSON "<corps_sans>"
    Et j'envoie POST "<route>" avec le corps JSON "<corps_avec>"
    Alors les "hits" des deux réponses sont identiques
    # NON PROUVÉ : « qu'avant l'ajout du paramètre » (non-régression historique) ne peut être vérifié que contre une version antérieure ; ici seulement défaut = 4/4 explicite

    Exemples:
      | patron          | route                              | corps_sans                                         | corps_avec                                                         |
      | double pédale   | /api/generate/patron-double-pedale | {"nombre_mesures": 2}                              | {"nombre_mesures": 2, "metrique": "4/4"}                           |
      | blast beat      | /api/generate/blast-beat           | {"nombre_mesures": 2, "style": "hammer"}           | {"nombre_mesures": 2, "style": "hammer", "metrique": "4/4"}        |
      | breakdown ternaire | /api/generate/breakdown         | {"nombre_mesures": 2, "style": "ternaire_triplet_feel"} | {"nombre_mesures": 2, "style": "ternaire_triplet_feel", "metrique": "4/4"} |
