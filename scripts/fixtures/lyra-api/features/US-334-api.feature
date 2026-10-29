# language: fr
@US-334 @REQ-334 @api
Fonctionnalité: Trouver des morceaux semblables par similarité multi-échelle (US-334)
  # REQ-334 - critères couverts à ce niveau : AC-1
  # RÉSOLU (code) : le JSON de /api/corpus-reference/similarite est en camelCase (pieceId, mesureDebut, mesureFin) ; « niveau » est obligatoire. Nécessite un corpus de référence indexé (absent).

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api @requiert-corpus-indexe
  Scénario: Résultat avec pieceId et bornes de segment
    Quand j'envoie POST "/api/corpus-reference/similarite" avec le corps JSON :
      """
      {"niveau": "mesure", "vecteur": [0.1, 0.2], "k": 5}
      """
    Alors la réponse a le statut 200
    Et chaque élément de la liste "resultats" a un champ "pieceId" non vide
    Et chaque élément de la liste "resultats" a un champ numérique "mesureDebut"
    Et chaque élément de la liste "resultats" a un champ numérique "mesureFin"
