# language: fr
@US-205 @REQ-205 @api
Fonctionnalité: Chercher des rimes françaises hors ligne (types autorisés, h aspiré) (US-205)
  # REQ-205 - critères couverts à ce niveau : AC-4, AC-5, AC-6

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api
  Scénario: Type de rime autre que parfaite/assonance refusé en français
    Quand j'envoie POST "/api/lyrics/rimes" avec le corps JSON "{\"mot\": \"maison\", \"langue\": \"francais\", \"types_rime\": [\"famille\"]}"
    Alors la réponse a le statut 422

  # RÉSOLU (code) : le genre du candidat dépend de la table rimes (vide ici) ; scénario exclu (dictionnaire absent).
  @AC-5 @api @requiert-dictionnaire-rimes
  Scénario: Genre de rime « meme » appliqué par défaut
    Quand j'envoie POST "/api/lyrics/rimes" avec le corps JSON "{\"mot\": \"maison\", \"langue\": \"francais\"}"
    Alors la réponse a le statut 200
    Et la liste "candidats" n'est pas vide

  @AC-6 @api @requiert-dictionnaire-rimes
  Scénario: h_aspire exposé pour le mot
    Quand j'envoie POST "/api/lyrics/rimes/prononciation" avec le corps JSON "{\"mot\": \"héros\", \"langue\": \"francais\"}"
    Alors la réponse a le statut 200
    Et le champ "h_aspire" vaut true
