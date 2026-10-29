# language: fr
@US-220 @REQ-220 @api
Fonctionnalité: Séquencer les ambiances d'un morceau par tirage parmi des humeurs candidates (US-220)
  # REQ-220 - critères couverts à ce niveau : AC-5, AC-6, AC-7
  # RÉSOLU (code) : vocabulaire d'humeurs = clés de GABARITS_PAR_HUMEUR (theme_musical_par_humeur.py), ex. joyeux, triste, sombre ; « joie », « tristesse » n'existent pas.

  Contexte:
    Soit l'API Lyra joignable

  @AC-5 @api
  Scénario: N humeurs parmi les candidates, jamais deux consécutives identiques
    Quand j'envoie POST "/api/generate/sequence-ambiance" avec le corps JSON "{\"nombre_sections\": 6, \"humeurs_candidates\": [\"joyeux\", \"triste\", \"sombre\"], \"random_seed\": 7}"
    Alors la réponse a le statut 200
    Et la liste "humeurs_par_section" contient 6 éléments
    Et tous les éléments de la liste "humeurs_par_section" sont parmi ["joyeux", "triste", "sombre"]
    Et la liste "humeurs_par_section" ne contient aucun doublon consécutif

  @AC-6 @api
  Scénario: Chanson par séquence : un thème par section, graine reproductible
    Quand j'envoie POST "/api/generate/chanson-par-sequence-ambiance" avec le corps JSON "{\"nombre_sections\": 4, \"nombre_mesures_par_section\": 8, \"humeurs_candidates\": [\"joyeux\", \"triste\"], \"random_seed\": 7}"
    Alors la réponse a le statut 200
    Et la liste "sections" contient 4 éléments
    Quand j'envoie POST "/api/generate/chanson-par-sequence-ambiance" avec le corps JSON "{\"nombre_sections\": 4, \"nombre_mesures_par_section\": 8, \"humeurs_candidates\": [\"joyeux\", \"triste\"], \"random_seed\": 7}"
    Alors les "sequence" des deux réponses sont identiques

  @AC-7 @api
  Scénario: Zéro section refusée
    Quand j'envoie POST "/api/generate/sequence-ambiance" avec le corps JSON "{\"nombre_sections\": 0, \"humeurs_candidates\": [\"joyeux\", \"triste\"]}"
    Alors la requête est refusée par une erreur 4xx

  @AC-7 @api
  Scénario: Une seule humeur candidate refusée
    Quand j'envoie POST "/api/generate/sequence-ambiance" avec le corps JSON "{\"nombre_sections\": 4, \"humeurs_candidates\": [\"joyeux\"]}"
    Alors la requête est refusée par une erreur 4xx

  @AC-7 @api
  Scénario: Humeur inconnue refusée
    Quand j'envoie POST "/api/generate/sequence-ambiance" avec le corps JSON "{\"nombre_sections\": 4, \"humeurs_candidates\": [\"joyeux\", \"inconnue\"]}"
    Alors la requête est refusée par une erreur 4xx
