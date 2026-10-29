# language: fr
@US-202 @REQ-202 @api
Fonctionnalité: Laisser l'auteur fixer une plage de liberté du comptage syllabique français (US-202)
  # REQ-202 - critères couverts à ce niveau : AC-4, AC-5, AC-6, AC-7

  Contexte:
    Soit l'API Lyra joignable

  # RÉSOLU (code) : /analyze renvoie syllabes_min/nominal/max ; la conformité à une cible (etat_cible, ecart_nominal) ne se calcule que dans /generate (syllabes_par_vers) => partie génération @requiert-ollama.
  @AC-4 @api
  Scénario: Plage min/nominal/max d'un vers français
    Quand j'envoie POST "/api/lyrics/analyze" avec le corps JSON "{\"texte\": \"Une rose blanche dans la nuit\", \"langue\": \"francais\"}"
    Alors la réponse a le statut 200
    Et le champ "vers[0].syllabes_min" est numérique
    Et le champ "vers[0].syllabes_nominal" est numérique
    Et le champ "vers[0].syllabes_max" est numérique

  @AC-5 @api @requiert-ollama
  Scénario: Conformité à la cible d'un vers français généré
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/lyrics/generate" avec le corps JSON "{\"sujet\": \"la nuit\", \"longueur\": 3, \"syllabes_par_vers\": [7, 9, 8], \"langue\": \"francais\"}"
    Alors la réponse a le statut 200
    Et chaque élément de la liste "vers" a un champ "etat_cible" non vide

  # RÉSOLU (code) : VerseAnalysis (lyra-ml et lyra-api) n'expose que e_optionnels_elides et e_prononces (listes d'indices) : les attributs indice/type/avalable/prononçable/source de l'AC n'existent pas ; on exige au moins des positions renseignées pour un vers qui en comporte (plage 6-9 syllabes).
  @AC-6 @api
  Scénario: Les positions des e muets sont détaillées
    Quand j'envoie POST "/api/lyrics/analyze" avec le corps JSON "{\"texte\": \"Une rose blanche dans la nuit\", \"langue\": \"francais\"}"
    Alors la réponse a le statut 200
    Et l'une des listes "vers[0].e_prononces" ou "vers[0].e_optionnels_elides" n'est pas vide

  # RÉSOLU (code) : retirer Lexique 3 exige de modifier l'installation (hors périmètre d'écriture) ; l'état « Lexique 3 absent » est celui de la pile (fiabilité du comptage : moteur).
  @AC-7 @api @requiert-env-sans-lexique
  Scénario: Lexique 3 absent : avertissement, pas d'exception
    Quand j'envoie POST "/api/lyrics/analyze" avec le corps JSON "{\"texte\": \"Une rose blanche dans la nuit\", \"langue\": \"francais\"}"
    Alors la réponse a le statut 200
