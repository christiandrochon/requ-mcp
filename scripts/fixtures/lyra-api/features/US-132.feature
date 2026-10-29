# language: fr
@api @US-132 @REQ-132
Fonctionnalité: Esquisse de croisement de genres : riff metal transposé en idiome orchestral

  Contexte:
    Soit l'API Lyra joignable
    Et un riff power chord palm-muté : fondamentale [40,42,44,45] et quinte [47,49,51,52], durées 0.5

  # réf: lyra-api/generation/ArrangementController.java:155 ; lyra-ml/app/main.py:3120 ; croisement_genres.py:68-130
  @AC-1 @api
  Scénario: Style par défaut : technique orchestrale, instruments couvrant l'ambitus, riff inchangé
    Quand j'envoie POST "/api/arrange/croisement-genres" avec le riff, "instruments_disponibles" ["violoncelle", "contrebasse", "flûte"] et sans style
    Alors la réponse a le statut 200
    Et le champ "technique_orchestrale" contient "cor bouché ou cordes en spiccato"
    Et "instruments_suggeres" contient l'instrument "violoncelle"
    Et "instruments_suggeres" ne contient pas l'instrument "flûte"
    # La réponse ne porte pas les hauteurs ; l'absence de modification du riff n'est pas observable côté API
    # NON PROUVÉ : « sans modifier ses hauteurs ni son rythme » (aucun champ de sortie ne les reprend)

  # réf: lyra-api/generation/ArrangementController.java:155 ; lyra-ml/app/main.py:3120 ; croisement_genres.py:44-48, 102-103
  @AC-2 @api
  Scénario: Style cello_metal : technique du violoncelle distordu
    Quand j'envoie POST "/api/arrange/croisement-genres" avec le riff et "style" "cello_metal"
    Alors la réponse a le statut 200
    Et le champ "technique_orchestrale" contient "violoncelle(s) en pression d'archet appuyée"

  # réf: lyra-api/generation/ArrangementController.java:155 ; lyra-ml/app/main.py:3120
  @AC-2 @api
  Scénario: Un style non documenté est rejeté
    Quand j'envoie POST "/api/arrange/croisement-genres" avec le riff et "style" "banjo_metal"
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée

  # réf: lyra-api/generation/ArrangementController.java:155 ; lyra-ml/app/main.py:3120 ; croisement_genres.py:104-111
  @AC-3 @api
  Scénario: Un riff qui n'est pas un power chord palm-muté est rejeté
    Quand j'envoie POST "/api/arrange/croisement-genres" avec fondamentale [60,62,64,65] et quinte [64,66,67,69]
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée

  # réf: lyra-api/generation/ArrangementController.java:155 ; lyra-ml/app/main.py:3120 ; suggest_instruments_for_range
  @AC-3 @api
  Scénario: Si aucun instrument ne couvre l'ambitus, la liste est vide sans erreur
    # RÉSOLU (exécution de suggest_instruments_for_range(40,54,[flûte])) : liste vide.
    Quand j'envoie POST "/api/arrange/croisement-genres" avec le riff et "instruments_disponibles" ["flûte"]
    Alors la réponse a le statut 200
    Et la liste "instruments_suggeres" est vide
