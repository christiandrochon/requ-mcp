# language: fr
@US-308 @REQ-308 @api
Fonctionnalité: Analyser le matériau d'une fugue (sujet, réponse, exposition, strette) (US-308)
  # REQ-308 - critères couverts à ce niveau : AC-1, AC-2, AC-3

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: Réponse tonale nécessaire pour un sujet qui touche la dominante
    Quand j'envoie POST "/api/analyze/fugue-necessite-reponse-tonale" avec le corps JSON :
      """
      {"sujet": "@notes:62,69,67,65,64,62", "mode": "dorien", "tonique": "Ré"}
      """
    Alors la réponse a le statut 200
    Et le champ "reponse_tonale_recommandee" vaut true

  @AC-1 @api
  Scénario: Réponse tonale générée pour le même sujet
    Quand j'envoie POST "/api/generate/reponse-tonale" avec le corps JSON :
      """
      {"sujet": "@notes:62,69,67,65,64,62", "mode": "dorien", "tonique": "Ré"}
      """
    Alors la réponse a le statut 200
    Et la liste "reponse" contient au moins 1 élément

  @AC-2 @api
  Scénario: Sujet et contre-sujet en quintes parallèles incompatibles
    Quand j'envoie POST "/api/analyze/fugue-compatibilite-verticale" avec le corps JSON :
      """
      {"sujet": "@notes:60,62,64,65", "contre_sujet": "@notes:53,55,57,58"}
      """
    Alors la réponse a le statut 200
    Et le champ "compatible" vaut false

  @AC-2 @api
  Scénario: Couple sans quinte ni octave parallèle compatible
    Quand j'envoie POST "/api/analyze/fugue-compatibilite-verticale" avec le corps JSON :
      """
      {"sujet": "@notes:60,62,64,65", "contre_sujet": "@notes:52,55,53,57"}
      """
    Alors la réponse a le statut 200
    Et le champ "compatible" vaut true

  @AC-3 @api
  Scénario: Strette générée puis vérifiée verticalement
    Quand j'envoie POST "/api/generate/stretto" avec le corps JSON :
      """
      {"sujet": "@notes:62,64,65,67,69"}
      """
    Alors la réponse a le statut 200
    Quand j'envoie POST "/api/analyze/stretto-compatibilite-verticale" avec le corps de la réponse précédente
    Alors la réponse a le statut 200
    Et le champ "compatible" est booléen
