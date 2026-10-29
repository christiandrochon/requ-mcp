# language: fr
@US-306 @REQ-306 @api
Fonctionnalité: Utiliser les gammes, modes et systèmes rythmiques du monde (US-306)
  # REQ-306 - critères couverts à ce niveau : AC-1, AC-2, AC-3

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: Gamme par tons : 6 notes
    Quand j'envoie POST "/api/generate/gamme-par-tons" avec le corps JSON "{\"tonique\": \"Do\"}"
    Alors la réponse a le statut 200
    Et la liste "notes" contient 6 éléments
    Et le champ "collection_index" est l'un de [0, 1]
    Et je mémorise le champ "collection_index" sous le nom "col_do"
    Quand j'envoie POST "/api/generate/gamme-par-tons" avec le corps JSON "{\"tonique\": \"Ré\"}"
    Alors le champ "collection_index" est égal à la variable "col_do"

  @AC-2 @api
  Scénario: Gabarit iqa' maqsoum
    Quand j'envoie POST "/api/generate/gabarit-iqaa" avec le corps JSON "{\"nom\": \"maqsoum\"}"
    Alors la réponse a le statut 200
    Et la liste "frappes" n'est pas vide
    Et chaque élément de la liste "frappes" a un champ "frappe" non vide
    Et chaque élément de la liste "frappes" a un champ numérique "position_temps"

  @AC-3 @api
  Scénario: Tala valide
    Quand j'envoie POST "/api/analyze/tala-valide" avec le corps JSON "{\"nom\": \"teentaal\", \"matras\": 16, \"vibhag\": [4, 4, 4, 4], \"sam_index\": 0, \"khali_indices\": [2]}"
    Alors la réponse a le statut 200
    Et le champ "valide" vaut true

  @AC-3 @api
  Scénario: Tala invalide : les vibhag ne somment pas aux matras
    Quand j'envoie POST "/api/analyze/tala-valide" avec le corps JSON "{\"nom\": \"teentaal\", \"matras\": 16, \"vibhag\": [4, 4, 4, 3], \"sam_index\": 0, \"khali_indices\": [2]}"
    Alors la réponse a le statut 200
    Et le champ "valide" vaut false
    Et le champ "justification" est non vide
