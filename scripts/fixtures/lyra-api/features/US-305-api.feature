# language: fr
@US-305 @REQ-305 @api
Fonctionnalité: Analyser en théorie atonale, dodécaphonique et spectrale (US-305)
  # REQ-305 - critères couverts à ce niveau : AC-1, AC-2, AC-3, AC-4
  # RÉSOLU (code) : la classe de Forte de l'accord majeur est rendue « 3-11B » par le code (3-11 = classe commune majeur/mineur) : l'oracle teste que numero_forte commence par « 3-11 ».

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: Classe de Forte et vecteur d'intervalles d'un accord majeur
    Quand j'envoie POST "/api/analyze/ensemble-classes-hauteurs" avec le corps JSON "{\"pitches\": [60, 64, 67]}"
    Alors la réponse a le statut 200
    Et le champ "numero_forte" contient "3-11"
    Et le champ "vecteur_intervalles" vaut [0, 0, 1, 1, 1, 0]

  @AC-2 @api
  Scénario: Série de 12 sons : 48 formes
    Quand j'envoie POST "/api/generate/serie-dodecaphonique" avec le corps JSON "{\"serie\": [\"Do\",\"Do#\",\"Ré\",\"Ré#\",\"Mi\",\"Fa\",\"Fa#\",\"Sol\",\"Sol#\",\"La\",\"La#\",\"Si\"]}"
    Alors la réponse a le statut 200
    Et la liste "formes" contient 48 éléments

  @AC-3 @api
  Scénario: Série de 11 notes refusée
    Quand j'envoie POST "/api/generate/serie-dodecaphonique" avec le corps JSON "{\"serie\": [\"Do\",\"Do#\",\"Ré\",\"Ré#\",\"Mi\",\"Fa\",\"Fa#\",\"Sol\",\"Sol#\",\"La\",\"La#\"]}"
    Alors la requête est refusée par une erreur 4xx

  @AC-3 @api
  Scénario: Série de 12 notes dont une répétée refusée
    Quand j'envoie POST "/api/generate/serie-dodecaphonique" avec le corps JSON "{\"serie\": [\"Do\",\"Do#\",\"Ré\",\"Ré#\",\"Mi\",\"Fa\",\"Fa#\",\"Sol\",\"Sol#\",\"La\",\"La#\",\"Do\"]}"
    Alors la requête est refusée par une erreur 4xx

  @AC-4 @api
  Scénario: Harmonie spectrale : partiel, fréquence, note proche, écart en cents
    Quand j'envoie POST "/api/generate/harmonie-spectrale" avec le corps JSON "{\"fondamentale_midi\": 36}"
    Alors la réponse a le statut 200
    Et chaque élément de la liste "partiels" a un champ numérique "frequence_hz"
    Et chaque élément de la liste "partiels" a un champ numérique "pitch_midi"
    Et chaque élément de la liste "partiels" a un champ numérique "ecart_cents"
