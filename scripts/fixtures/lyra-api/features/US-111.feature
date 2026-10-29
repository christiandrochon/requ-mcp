# language: fr
@api @US-111 @REQ-111
Fonctionnalité: Cartes de tempo : accelerando et ritardando par paliers

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:392 ; lyra-ml/app/main.py:2976 ; musiques_de_transe.py:137
  @AC-2 @api
  Scénario: Le ritardando décroît strictement par paliers jusqu'au tempo final
    Quand j'envoie POST "/api/generate/ritardando-par-paliers" avec le corps JSON :
      """
      {"tempo_depart": 140, "tempo_arrivee": 100, "nombre_paliers": 4}
      """
    Alors la réponse a le statut 200
    Et la liste "paliers" contient 4 éléments
    Et les valeurs "tempo_bpm" de "paliers" sont strictement décroissantes
    Et le premier élément de "paliers" a "tempo_bpm" égal à 140
    Et le dernier élément de "paliers" a "tempo_bpm" égal à 100

  # réf: lyra-api/generation/GenerationController.java:1142 ; lyra-ml/app/main.py:4688 ; musiques_de_transe.py:85-115
  @AC-3 @api
  Scénario: L'accelerando de 100 à 140 bpm en 4 paliers est croissant à pas régulier
    Quand j'envoie POST "/api/generate/accelerando-par-paliers" avec le corps JSON :
      """
      {"tempo_depart": 100, "tempo_arrivee": 140, "nombre_paliers": 4}
      """
    Alors la réponse a le statut 200
    Et la liste "paliers" contient 4 éléments
    Et les valeurs "tempo_bpm" de "paliers" sont strictement croissantes
    Et l'écart entre deux paliers consécutifs de "paliers" est constant à 0.01 près
    Et le premier élément de "paliers" a "tempo_bpm" égal à 100
    Et le dernier élément de "paliers" a "tempo_bpm" égal à 140

  # réf: lyra-api/generation/GenerationController.java:392 ; lyra-ml/app/main.py:2976 ; musiques_de_transe.py:153-156
  @AC-4 @api
  Plan du Scénario: Un ritardando incohérent est refusé (<cas>)
    Quand j'envoie POST "/api/generate/ritardando-par-paliers" avec le corps JSON :
      """
      {"tempo_depart": <depart>, "tempo_arrivee": <arrivee>, "nombre_paliers": <paliers>}
      """
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée

    Exemples:
      | cas                            | depart | arrivee | paliers |
      | arrivée supérieure au départ   | 100    | 140     | 4       |
      | arrivée égale au départ        | 100    | 100     | 4       |
      | moins de 2 paliers             | 140    | 100     | 1       |
