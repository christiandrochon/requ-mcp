# language: fr
@US-213 @REQ-213 @api
Fonctionnalité: Vérifier l'adéquation des paroles à la technique vocale et à la tessiture (US-213)
  # REQ-213 - critères couverts à ce niveau : AC-4, AC-5, AC-7
  # RÉSOLU (code) : techniques valides = growl, belt, sifflet (adequation_vocale.py) ; adequation ∈ favorable | defavorable | indetermine.

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api
  Scénario: Technique inconnue refusée
    Quand j'envoie POST "/api/lyrics/adequation-vocale" avec le corps JSON "{\"mot\": \"rage\", \"technique\": \"yodel\"}"
    Alors la requête est refusée par une erreur 4xx
    Et le message d'erreur est en français

  @AC-5 @api
  Scénario: Adéquation d'un mot à growl, belt et sifflet
    Quand j'envoie POST "/api/lyrics/adequation-vocale" avec le corps JSON "{\"mot\": \"rage\", \"technique\": \"growl\"}"
    Alors la réponse a le statut 200
    Et le champ "adequation" est l'un de ["favorable", "defavorable", "indetermine"]
    Quand j'envoie POST "/api/lyrics/adequation-vocale" avec le corps JSON "{\"mot\": \"rage\", \"technique\": \"belt\"}"
    Alors le champ "adequation" est l'un de ["favorable", "defavorable", "indetermine"]
    Quand j'envoie POST "/api/lyrics/adequation-vocale" avec le corps JSON "{\"mot\": \"rage\", \"technique\": \"sifflet\"}"
    Alors le champ "adequation" est l'un de ["favorable", "defavorable", "indetermine"]

  @AC-5 @api
  Scénario: Mot vide refusé
    Quand j'envoie POST "/api/lyrics/adequation-vocale" avec le corps JSON "{\"mot\": \"\", \"technique\": \"growl\"}"
    Alors la requête est refusée par une erreur 4xx

  @AC-7 @api
  Scénario: Suggestion de technique selon l'agressivité
    Quand j'envoie POST "/api/lyrics/suggestion-technique-vocale" avec le corps JSON "{\"texte\": \"rage et feu\", \"niveau_agressivite\": 0.7}"
    Alors le champ "technique_suggeree" vaut "growl"
    Quand j'envoie POST "/api/lyrics/suggestion-technique-vocale" avec le corps JSON "{\"texte\": \"rage et feu\", \"niveau_agressivite\": 0.3}"
    Alors le champ "technique_suggeree" vaut "sifflet"
    Quand j'envoie POST "/api/lyrics/suggestion-technique-vocale" avec le corps JSON "{\"texte\": \"rage et feu\", \"niveau_agressivite\": 0.5}"
    Alors le champ "technique_suggeree" vaut "belt"
    Et le champ "convergence" est booléen

  @AC-7 @api
  Scénario: Suggestion avec un texte vide refusée
    Quand j'envoie POST "/api/lyrics/suggestion-technique-vocale" avec le corps JSON "{\"texte\": \"\", \"niveau_agressivite\": 0.5}"
    Alors la requête est refusée par une erreur 4xx
