# language: fr
@api @US-113 @REQ-113
Fonctionnalité: Fiche de qualité mélodique explicable, sans score unique

  Contexte:
    Soit l'API Lyra joignable
    Et une mélodie de 12 notes en 4/4 (fixture "melodie-12-notes.json")

  # réf: lyra-api/analysis/AnalysisController.java:754 ; lyra-ml/app/main.py:2110 ; fiche.py:189-218 ; constats.py:145-165
  @AC-1 @api
  Scénario: La fiche contient les familles I1 à I8 et aucun score global
    Quand j'envoie POST "/api/analyze/qualite-melodique" avec le motif de la fixture et "metrique" "4/4"
    Alors la réponse a le statut 200
    Et les "famille" de "familles" valent successivement "I1, I2, I3, I4, I5, I6, I7, I8"
    Et chaque élément de "familles" a un champ "niveau" non vide
    Et la racine de la réponse n'a aucun champ nommé "note", "score", "moyenne" ou "note_globale"

  # réf: lyra-api/analysis/AnalysisController.java:754 ; lyra-ml/app/main.py:2110 ; constats.py:48-68
  @AC-2 @api
  Scénario: Un constat de jugement porte règle, source, statut de preuve et portée ; réserve/écart sont localisés
    Quand j'envoie POST "/api/analyze/qualite-melodique" avec le motif de la fixture et "metrique" "4/4"
    Alors la réponse a le statut 200
    Et tout constat de "familles[*].composantes" où "portee" vaut "jugement" a "regle", "source", "statut_preuve" et "portee_application" non vides
    Et tout constat de "familles[*].composantes" où "niveau" vaut "reserve" ou "ecart" a "localisation" non vide

  # réf: lyra-api/analysis/AnalysisController.java:754 ; lyra-ml/app/main.py:2110 ; requete.py:398-404 ; main.py:2110 (422 documenté)
  @AC-3 @api
  Plan du Scénario: Source mal fournie : refus 422 (<cas>)
    Quand j'envoie POST "/api/analyze/qualite-melodique" avec le corps préparé pour le cas "<cas>"
    Alors la requête est refusée avec le statut 422

    Exemples:
      | cas                                        |
      | motif et partition ensemble                |
      | ni motif ni partition                      |
