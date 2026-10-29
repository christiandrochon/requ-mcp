# language: fr
@api @US-120 @REQ-120
Fonctionnalité: Fills et transitions entre sections

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:404 ; lyra-ml/app/main.py:3187 ; groove.py:260-305
  @AC-1 @api
  Scénario: Le fill « build » sur 4 temps contient caisse claire, tom et grosse caisse
    Quand j'envoie POST "/api/generate/fill-transition" avec le corps JSON :
      """
      {"type_fill": "build", "nombre_temps": 4}
      """
    Alors la réponse a le statut 200
    Et l'ensemble des "instrument" de "coups" est exactement {"kick", "snare", "tom"}

  # réf: lyra-api/generation/GenerationController.java:404 ; lyra-ml/app/main.py:3187
  @AC-1 @api
  Plan du Scénario: Les fills <type> ne contiennent que de la caisse claire
    Quand j'envoie POST "/api/generate/fill-transition" avec le corps JSON :
      """
      {"type_fill": "<type>", "nombre_temps": 4}
      """
    Alors la réponse a le statut 200
    Et l'ensemble des "instrument" de "coups" est exactement {"snare"}

    Exemples:
      | type        |
      | roll        |
      | flam        |
      | paradiddle  |

  # CONSTAT : TYPE_FILL_PAR_INTENSITE_DESTINATION (groove.py:242) n'est référencé par aucune route ni fonction (grep) ; aucun paramètre
  # « destination » dans FillContenuRequestDto. Le comportement « plus_intense -> build / plus_calme -> flam » n'est pas atteignable via l'API.
  @AC-2 @api @non-testable
  Scénario: Sans type explicite, la destination détermine le type de fill
    # A CONFIRMER : champ et endpoint inexistants dans l'API
    Quand je demande un fill sans type vers une section "plus_intense"
    Alors le fill est de type "build"

  # réf: lyra-api/generation/GenerationController.java:404 ; lyra-ml/app/main.py:3187 ; groove.py:277-280
  @AC-3 @api
  Plan du Scénario: Un type hors liste ou un nombre de temps non positif est refusé (<cas>)
    Quand j'envoie POST "/api/generate/fill-transition" avec le corps JSON :
      """
      {"type_fill": "<type>", "nombre_temps": <temps>}
      """
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée

    Exemples:
      | cas             | type     | temps |
      | type inconnu    | cascade  | 4     |
      | zéro temps      | build    | 0     |
      | temps négatif   | roll     | -3    |
