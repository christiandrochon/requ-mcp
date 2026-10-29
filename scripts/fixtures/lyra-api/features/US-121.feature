# language: fr
@api @US-121 @REQ-121
Fonctionnalité: Légende de percussion pour la tête de partition

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/notation/NotationController.java:71 ; lyra-ml/app/main.py:2589 ; musicxml.py:402-425
  @AC-1 @api
  Scénario: La légende est dédupliquée dans l'ordre de première apparition
    Quand j'envoie POST "/api/notation/legende-percussion" avec le corps JSON :
      """
      {"instruments": ["grosse caisse", "caisse claire", "grosse caisse", "charleston"]}
      """
    Alors la réponse a le statut 200
    Et le champ "instruments" vaut ["grosse caisse", "caisse claire", "charleston"]

  # réf: lyra-api/notation/NotationController.java:71 ; lyra-ml/app/main.py:2589 ; musicxml.py:419
  @AC-2 @api
  Scénario: Une liste vide est refusée
    Quand j'envoie POST "/api/notation/legende-percussion" avec le corps JSON :
      """
      {"instruments": []}
      """
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée
