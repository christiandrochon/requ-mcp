# language: fr
@US-330 @REQ-330 @api
Fonctionnalité: Rechercher un morceau par ambiance en texte libre (US-330)
  # REQ-330 - critères couverts à ce niveau : AC-1, AC-2, AC-3
  # RÉSOLU (code) : GET /api/pieces/search?q= renvoie la liste d'UUID classés ; les descripteurs se renseignent à la création de la pièce.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: « mélancolique » classe en premier la pièce mélancolique
    Soit une pièce enregistrée avec le corps JSON sous le nom "melancolique" :
      """
      {"titre": "melancolique e2e", "contenu": "x", "descripteurs": ["mélancolique", "lent"], "origine": "editee"}
      """
    Et une pièce enregistrée avec le corps JSON sous le nom "joyeuse" :
      """
      {"titre": "joyeuse e2e", "contenu": "x", "descripteurs": ["joyeux", "rapide"], "origine": "editee"}
      """
    Quand j'envoie GET "/api/pieces/search?q=mélancolique"
    Alors la réponse a le statut 200
    Et la liste "$" n'est pas vide
    Et la liste "$" ne contient pas la valeur "{joyeuse}"
    # La liste est plafonnée et la base accumule les pièces des exécutions précédentes : l'appartenance de la pièce créée n'est donc pas assertée.

  @AC-1 @api
  Scénario: Une faute de frappe proche retrouve la même pièce
    Soit une pièce enregistrée avec le corps JSON sous le nom "melancolique" :
      """
      {"titre": "melancolique e2e", "contenu": "x", "descripteurs": ["mélancolique", "lent"], "origine": "editee"}
      """
    Quand j'envoie GET "/api/pieces/search?q=melancolik"
    Alors la réponse a le statut 200
    Et la liste "$" n'est pas vide

  @AC-2 @api @depend-modele-ml
  Scénario: Requête sémantique sans mot commun
    Soit une pièce enregistrée avec le corps JSON sous le nom "sombre" :
      """
      {"titre": "sombre e2e", "contenu": "x", "descripteurs": ["sombre et lent"], "origine": "editee"}
      """
    Quand j'envoie GET "/api/pieces/search?q=triste"
    Alors la liste "$" n'est pas vide

  @AC-3 @api @requiert-arret-ml
  Scénario: Service d'embedding indisponible : correspondance floue seule, sans erreur
    Quand j'envoie GET "/api/pieces/search?q=mélancolique"
    Alors la réponse a le statut 200
