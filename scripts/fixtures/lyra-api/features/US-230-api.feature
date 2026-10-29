# language: fr
@US-230 @REQ-230 @api
Fonctionnalité: Expliquer pourquoi une décision de génération a été prise (US-230)
  # REQ-230 - critères couverts à ce niveau : AC-1

  Contexte:
    Soit l'API Lyra joignable

  # Passe par /api/nlu/command (Ollama requis pour classer « pourquoi cet accord »).
  @AC-1 @api @depend-modele-ml @requiert-ollama
  Scénario: « pourquoi cet accord » renvoie la règle appliquée
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 110, "mode": "ionien", "tonique": "Do", "nombre_mesures": 4, "random_seed": 3}
      """
    Alors la réponse a le statut 200
    Quand j'envoie POST "/api/nlu/command" avec le corps JSON "{\"texte\": \"pourquoi cet accord\", \"positionMesure\": 1, \"positionTemps\": 0.0}"
    Alors la réponse a le statut 200
    Et le champ "resultat.explication" est non vide
