# language: fr
@api @US-105 @REQ-105
Fonctionnalité: Variantes harmoniques avancées et harmonie de couleur hors fonction tonale

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:830 ; lyra-ml/app/main.py:3949 ; progressions_repertoire.py:81
  @AC-1 @api
  Scénario: Le cycle Coltrane renvoie 6 accords, sans tonique de clôture
    Quand j'envoie POST "/api/generate/cycle-coltrane" avec le corps JSON :
      """
      {"tonique_depart": "Si"}
      """
    Alors la réponse a le statut 200
    Et la liste "accords" contient 6 éléments
    Et les éléments de "accords" ont pour "fonction" successivement "majeur, dominante, majeur, dominante, majeur, dominante"
    # RÉSOLU (code + exécution) : le dernier accord du cycle est une dominante (6 accords, fonction majeur/dominante alternées).
    Et le dernier élément de "accords" a "fonction" égal à "dominante"

  # réf: lyra-api/generation/ArrangementController.java:473 ; lyra-ml/app/main.py:5290 ; chord_progression.py:1692 ; fixture accords diatoniques de Do ionien
  @AC-2 @api
  Scénario: Les substituts de I ne retiennent que la famille tonique avec au moins 2 notes communes
    Soit les accords diatoniques de "Do" en mode "ionien" (fixture "accords-do-ionien.json")
    Quand j'envoie POST "/api/arrange/substituts-valides" avec l'accord I et les 7 accords diatoniques comme candidats
    Alors la réponse a le statut 200
    Et chaque élément de "substituts" appartient à la famille fonctionnelle "tonique" (degrés 0, 2 ou 5)
    Et chaque élément de "substituts" partage au moins 2 notes avec l'accord d'origine
    Et aucun élément de "substituts" n'a le même "degree_index" que l'accord d'origine

  # réf: lyra-api/generation/ArrangementController.java:484 ; lyra-ml/app/main.py:5306 ; chord_progression.py:1742-1790
  @AC-3 @api
  Scénario: Cadence rompue : vi, et iii seulement si la variante est autorisée
    Quand j'envoie POST "/api/arrange/substituts-cadence-rompue" avec le corps JSON :
      """
      {"mode": "ionien", "tonique": "Do", "autoriser_iii": false}
      """
    Alors la réponse a le statut 200
    Et les éléments de "substituts" ont pour "roman_numeral" successivement "vi"
    Quand j'envoie POST "/api/arrange/substituts-cadence-rompue" avec le corps JSON :
      """
      {"mode": "ionien", "tonique": "Do", "autoriser_iii": true}
      """
    Alors la réponse a le statut 200
    Et les éléments de "substituts" ont pour "roman_numeral" successivement "vi, iii"

  # réf: lyra-api/generation/GenerationController.java:879 ; lyra-ml/app/main.py:4110 ; harmonie_non_fonctionnelle.py:35
  @AC-4 @api
  Scénario: Le planing transpose le même gabarit sur chaque fondamentale
    Quand j'envoie POST "/api/generate/harmonie-glissement" avec le corps JSON :
      """
      {"fondamentales": ["Do", "Fa", "Sol"], "gabarit": [0, 4, 7]}
      """
    Alors la réponse a le statut 200
    Et le champ "gabarit" vaut [0, 4, 7]
    Et la liste "accords" contient 3 éléments
    Et le champ "accords[0].notes" vaut ["Do", "Mi", "Sol"]
    Et le champ "accords[1].notes" vaut ["Fa", "La", "Do"]
    Et le champ "accords[2].notes" vaut ["Sol", "Si", "Ré"]
