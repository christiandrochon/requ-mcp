# language: fr
@US-236 @REQ-236 @api
Fonctionnalité: Renseigner les droits et la provenance d'une composition (US-236)
  # REQ-236 - critères couverts à ce niveau : AC-4, AC-5
  # RÉSOLU (code) : schéma des droits lu par PieceService.verifierDroits : { auteurs: [{nom, role, pourcentage}], dateComposition } ; messages sans accent (« aucun auteur renseigne », « somme des pourcentages … »).

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api
  Scénario: Pourcentages différents de 100 : enregistrés, vérification négative
    Soit une pièce enregistrée sous le nom "pieceId"
    Quand j'envoie PUT "/api/pieces/{pieceId}/droits" avec le corps JSON :
      """
      {"droits": {"auteurs": [{"nom": "A", "role": "compositeur", "pourcentage": 60}], "dateComposition": "2026-01-01"}}
      """
    Alors la réponse a le statut 200
    Quand j'envoie GET "/api/pieces/{pieceId}/verification-droits"
    Alors la réponse a le statut 200
    Et le champ "pretPourUsageCommercial" vaut false
    Et le corps de la réponse contient "somme des pourcentages"

  @AC-5 @api
  Scénario: Sans auteur : non prêt
    Soit une pièce enregistrée sous le nom "pieceId"
    Quand j'envoie PUT "/api/pieces/{pieceId}/droits" avec le corps JSON :
      """
      {"droits": {"auteurs": [], "dateComposition": "2026-01-01"}}
      """
    Et j'envoie GET "/api/pieces/{pieceId}/verification-droits"
    Alors le champ "pretPourUsageCommercial" vaut false
    Et le corps de la réponse contient "aucun auteur renseigne"

  @AC-5 @api
  Scénario: Avec un auteur à 100 % et une date : prêt
    Soit une pièce enregistrée sous le nom "pieceId"
    Quand j'envoie PUT "/api/pieces/{pieceId}/droits" avec le corps JSON :
      """
      {"droits": {"auteurs": [{"nom": "A", "role": "compositeur", "pourcentage": 100}], "dateComposition": "2026-01-01"}}
      """
    Et j'envoie GET "/api/pieces/{pieceId}/verification-droits"
    Alors le champ "pretPourUsageCommercial" vaut true
    Et la liste "problemes" est vide
