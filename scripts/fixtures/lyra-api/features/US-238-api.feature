# language: fr
@US-238 @REQ-238 @api
Fonctionnalité: Étiqueter les sections par scène et intention narrative (musique de film) (US-238)
  # REQ-238 - critères couverts à ce niveau : AC-3, AC-4, AC-5
  # RÉSOLU (code) : types de scène valides = horreur, romance, action, mystere, tension_suspense (musique_de_film.py).
  # RÉSOLU (code) : l'étiquette passe par un embedding servi par Ollama (absent) : cas valide @requiert-ollama ; les refus d'entrée sont vérifiés sans modèle.

  Contexte:
    Soit l'API Lyra joignable

  @AC-3 @api @depend-modele-ml @requiert-ollama
  Scénario: Étiquette narrative valide
    Quand j'envoie POST "/api/arrange/etiquette-narrative" avec le corps JSON "{\"type_scene\": \"action\", \"intention_narrative\": \"tension croissante\", \"intensite\": 0.8}"
    Alors la réponse a le statut 200
    Et le champ "etiquette.type_scene" vaut "action"
    Et le champ "embedding" est une liste

  @AC-4 @api
  Scénario: Intention narrative vide refusée
    Quand j'envoie POST "/api/arrange/etiquette-narrative" avec le corps JSON "{\"type_scene\": \"action\", \"intention_narrative\": \"\", \"intensite\": 0.8}"
    Alors la requête est refusée par une erreur 4xx

  @AC-5 @api
  Scénario: Type de scène inconnu refusé
    Quand j'envoie POST "/api/arrange/etiquette-narrative" avec le corps JSON "{\"type_scene\": \"scene-inexistante\", \"intention_narrative\": \"tension croissante\", \"intensite\": 0.8}"
    Alors la requête est refusée par une erreur 4xx
