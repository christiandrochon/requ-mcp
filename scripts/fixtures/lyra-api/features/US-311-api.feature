# language: fr
@US-311 @REQ-311 @api
Fonctionnalité: Exporter le conducteur et les parties en PDF (US-311)
  # REQ-311 - critères couverts à ce niveau : AC-1, AC-2
  # RÉSOLU (code) : le PDF passe par MuseScore (absent de la pile) ; l'état « MuseScore introuvable » est celui de la pile : scénario AC-2 classé environnement-sans-musescore (la variable nommée est lue dans le message).

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api @requiert-musescore
  Scénario: PDF conducteur + un PDF par instrument
    Quand j'envoie POST "/api/notation/partition/exporter" avec la fixture "partition-exemple.json" et les champs :
      """
      {"formats": ["pdf_conducteur"]}
      """
    Alors la réponse a le statut 200
    Et la liste "fichiers" contient au moins 2 éléments

  @AC-2 @api
  Scénario: MuseScore introuvable : erreur nommant la variable de configuration
    Quand j'envoie POST "/api/notation/partition/exporter" avec la fixture "partition-exemple.json" et les champs :
      """
      {"formats": ["pdf_conducteur"]}
      """
    Alors la réponse a le statut 503
    Et le corps de la réponse contient "MuseScore"
    Et le corps de la réponse contient "LYRA_ML_MUSESCORE_PATH"
