# language: fr
@US-304 @REQ-304 @api
Fonctionnalité: Valider une séquence de sections et obtenir des gabarits de forme (US-304)
  # REQ-304 - critères couverts à ce niveau : AC-3, AC-4, AC-5, AC-6
  # RÉSOLU (code) : GET /api/generate/gabarit-periode n'existe pas (405 sur POST de sondage ; route en POST à vérifier à l'exécution).

  Contexte:
    Soit l'API Lyra joignable

  @AC-3 @api
  Scénario: Séquence vide refusée
    Quand j'envoie POST "/api/analyze/sequence-sections" avec le corps JSON "{\"sections\": []}"
    Alors la requête est refusée par une erreur 4xx
    Et la réponse porte un message d'erreur non vide

  @AC-4 @api
  Scénario: Séquence conforme
    Quand j'envoie POST "/api/analyze/sequence-sections" avec le corps JSON "{\"sections\": [\"I\",\"A\",\"B\",\"A\",\"B\",\"C\",\"B\",\"O\"]}"
    Alors la réponse a le statut 200
    Et le champ "conforme" vaut true
    Et la liste "alertes" est vide

  @AC-4 @api
  Scénario: Séquence sans contraste
    Quand j'envoie POST "/api/analyze/sequence-sections" avec le corps JSON "{\"sections\": [\"I\",\"A\",\"B\",\"A\",\"B\",\"O\"]}"
    Alors le champ "conforme" vaut false
    Et la liste "alertes" n'est pas vide

  @AC-5 @api
  Scénario: Répétition excessive d'une section nommée avec son indice
    Quand j'envoie POST "/api/analyze/sequence-sections" avec le corps JSON "{\"sections\": [\"I\",\"A\",\"A\",\"A\",\"B\",\"C\",\"O\"]}"
    Alors la réponse a le statut 200
    Et la liste "alertes" n'est pas vide
    Et le corps de la réponse contient "A"

  @AC-6 @api
  Scénario: Gabarit de période : antécédent et conséquent
    Quand j'envoie GET "/api/generate/gabarit-periode"
    Alors la réponse a le statut 200
    Et la liste "sous_phrases" contient au moins 2 éléments

  @AC-6 @api
  Scénario: Forme compound AABA avec et sans second pont
    Quand j'envoie POST "/api/generate/forme-compound-aaba" avec le corps JSON "{\"second_pont\": false}"
    Alors la réponse a le statut 200
    Quand j'envoie POST "/api/generate/forme-compound-aaba" avec le corps JSON "{\"second_pont\": true}"
    Alors la réponse a le statut 200
    Et la liste "supersections" contient plus d'éléments que la liste "supersections" de la réponse précédente
