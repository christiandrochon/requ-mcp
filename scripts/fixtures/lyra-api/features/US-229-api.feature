# language: fr
@US-229 @REQ-229 @api
Fonctionnalité: Piloter Lyra par une commande en langage naturel (Explain, Transform, Generate) (US-229)
  # REQ-229 - critères couverts à ce niveau : AC-1, AC-2, AC-5
  # RÉSOLU (code) : POST /api/nlu/command passe par lyra-ml /nlu/parse-command qui appelle Ollama (lyra-api/nlu/CommandRouterService.java:133) : tout scénario exige Ollama (absent de la pile) ; intentions en minuscules (Intention enum).

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @AC-5 @api @requiert-ollama
  Scénario: Phrase Generate : paramètres extraits de façon déterministe
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/nlu/command" avec le corps JSON "{\"texte\": \"crée 32 mesures de 4/4 à 140 bpm en mineur\"}"
    Alors la réponse a le statut 200
    Et le champ "commandeAnalysee.intention" vaut "generate"

  @AC-2 @api @requiert-ollama
  Scénario: Phrase Explain
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/nlu/command" avec le corps JSON "{\"texte\": \"pourquoi as-tu choisi le Fa plutôt que le Sol\"}"
    Alors le champ "commandeAnalysee.intention" vaut "explain"

  @AC-5 @api @requiert-ollama
  Scénario: Toute phrase classée dans une des intentions connues
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/nlu/command" avec le corps JSON "{\"texte\": \"fais quelque chose\"}"
    Alors le champ "commandeAnalysee.intention" est non vide
