# language: fr
@US-214 @REQ-214 @api
Fonctionnalité: Détecter les clichés, vérifier la cohérence du champ lexical et proposer un titre (US-214)
  # REQ-214 - critères couverts à ce niveau : AC-1, AC-4, AC-5, AC-6
  # RÉSOLU (code) : clichés catalogués = CLICHES_PAR_SOUS_GENRE (cliches_metal.py) ; « flammes de l'enfer » n'y figure pas, « dragon » (power_metal) si.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: Cliché catalogué signalé avec sa position
    Quand j'envoie POST "/api/lyrics/detect-cliches" avec le corps JSON "{\"texte\": \"Je chante la mer\nLe dragon se réveille\"}"
    Alors la réponse a le statut 200
    Et la liste "occurrences" contient un élément dont "cliche" vaut "dragon"
    Et la liste "occurrences" contient un élément dont "indice_ligne" vaut 1

  @AC-4 @api
  Scénario: Texte vide refusé (clichés)
    Quand j'envoie POST "/api/lyrics/detect-cliches" avec le corps JSON "{\"texte\": \"\"}"
    Alors la requête est refusée par une erreur 4xx

  @AC-5 @api @depend-modele-ml @requiert-ollama
  Scénario: Champ lexical : vers hors champ
    Quand j'envoie POST "/api/lyrics/coherence-lexicale" avec le corps JSON "{\"vers\": [\"la mer calme\", \"la vague sur le sable\", \"mon moteur diesel\"]}"
    Alors la réponse a le statut 200
    Et la liste "vers_hors_champ" n'est pas vide

  @AC-5 @api
  Scénario: Champ lexical : moins de 2 vers refusé
    Quand j'envoie POST "/api/lyrics/coherence-lexicale" avec le corps JSON "{\"vers\": [\"un seul vers\"]}"
    Alors la requête est refusée par une erreur 4xx

  @AC-6 @api
  Scénario: Titre : vers le plus répété, sinon premier vers
    Quand j'envoie POST "/api/lyrics/extraire-titre" avec le corps JSON "{\"vers\": [\"Hello\", \"Autre ligne\", \"Hello\"]}"
    Alors le champ "titre_suggere" vaut "Hello"
    Quand j'envoie POST "/api/lyrics/extraire-titre" avec le corps JSON "{\"vers\": [\"Premier\", \"Deuxième\", \"Troisième\"]}"
    Alors le champ "titre_suggere" vaut "Premier"
    Et le champ "fiabilite" vaut "aucune_repetition_detectee"
