# language: fr
@api @US-126 @REQ-126
Fonctionnalité: Orchestration avec instruments du monde et sémiotique orchestrale

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/ArrangementController.java:120 ; lyra-ml/app/main.py:2950 ; topics_instrumentaux.py:101-104, 432-447
  @AC-1 @api
  Scénario: Le topic de la trompette est militaire/héraldique, fiabilité « academique »
    Quand j'envoie POST "/api/arrange/topic-instrumental" avec le corps JSON :
      """
      {"instrument": "trompette"}
      """
    Alors la réponse a le statut 200
    Et le champ "connotation" vaut "militaire/héraldique"
    Et le champ "fiabilite" vaut "academique"

  # réf: lyra-api/generation/ArrangementController.java:120 ; lyra-ml/app/main.py:2950 ; topics_instrumentaux.py:25 (timbales volontairement sans entrée)
  @AC-1 @api
  Scénario: Les timbales n'ont aucun topic documenté : erreur
    Quand j'envoie POST "/api/arrange/topic-instrumental" avec le corps JSON :
      """
      {"instrument": "timbales"}
      """
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée

  # réf: lyra-api/generation/ArrangementController.java:131 ; lyra-ml/app/main.py:2963 ; topics_instrumentaux.py:450-470
  @AC-2 @api
  Scénario: L'intention « chasse » renvoie le topic du cor
    Quand j'envoie POST "/api/arrange/topics-pour-intention" avec le corps JSON :
      """
      {"intention": "chasse"}
      """
    Alors la réponse a le statut 200
    Et un élément de la réponse a "instrument" égal à "cor"

  # réf: lyra-api/generation/ArrangementController.java:131 ; lyra-ml/app/main.py:2963
  @AC-2 @api
  Scénario: Une intention sans correspondance renvoie une liste vide, sans erreur
    Quand j'envoie POST "/api/arrange/topics-pour-intention" avec le corps JSON :
      """
      {"intention": "zzz-aucune-correspondance"}
      """
    Alors la réponse a le statut 200
    Et la réponse est une liste vide

  # réf: lyra-api/generation/ArrangementController.java:205 ; lyra-ml/app/main.py:3200 ; instruments_ethniques.py:28-95, 109-130
  @AC-3 @api
  Scénario: Le sitar renvoie région/tradition et fonction réelle
    Quand j'envoie POST "/api/arrange/instrument-ethnique" avec le corps JSON :
      """
      {"nom": "sitar"}
      """
    Alors la réponse a le statut 200
    Et le champ "region_tradition" est non vide
    Et le champ "fonction_reelle" est non vide
    # A CONFIRMER : connotation importée et avertissement culturel sont facultatifs (None) ; à vérifier cas par cas sur un instrument qui les porte
    Et les champs "connotation_stereotype_importe" et "avertissement_culturel" sont présents dans la réponse (valeur éventuellement nulle)

  # réf: lyra-api/generation/ArrangementController.java:205 ; lyra-ml/app/main.py:3200 ; instruments_ethniques.py:128
  @AC-3 @api
  Scénario: Un nom hors de la liste est rejeté
    Quand j'envoie POST "/api/arrange/instrument-ethnique" avec le corps JSON :
      """
      {"nom": "guitare-classique"}
      """
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée

  # ÉCART SPEC/CODE : le critère parle de « 11 instruments » ; instruments_ethniques.py:28-95 en contient 13 (sitar, tabla, duduk, kora, djembe, erhu,
  # shakuhachi, didgeridoo, cornemuse_ecossaise, bouzouki, handpan, oud, koto). Aucun scénario ne fige le nombre.
