# language: fr
@api @US-122 @REQ-122
Fonctionnalité: Déférence rythmique de l'accompagnement à l'instrument au premier plan

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/ArrangementController.java:143 ; lyra-ml/app/main.py:3101 ; arrangement.py:2076-2137
  @AC-1 @api
  Scénario: Avec le facteur par défaut, 8 notes d'accompagnement sont ramenées à 4 attaques, durée totale inchangée
    Quand j'envoie POST "/api/arrange/deference-rythmique" avec le corps JSON :
      """
      {"voix_premier_plan": [{"pitch":72,"duree_temps":1},{"pitch":74,"duree_temps":1},{"pitch":76,"duree_temps":1},{"pitch":77,"duree_temps":1}],
       "voix_accompagnement": [{"instrument":"violon","role":"harmonie/soutien","justification":"fixture",
          "notes":[{"pitch":60,"duree_temps":0.5},{"pitch":62,"duree_temps":0.5},{"pitch":64,"duree_temps":0.5},{"pitch":65,"duree_temps":0.5},
                   {"pitch":67,"duree_temps":0.5},{"pitch":65,"duree_temps":0.5},{"pitch":64,"duree_temps":0.5},{"pitch":62,"duree_temps":0.5}]}]}
      """
    Alors la réponse a le statut 200
    Et la liste "voix_accompagnement_reduites[0].notes" contient 4 éléments
    Et la somme des "duree_temps" de "voix_accompagnement_reduites[0].notes" vaut 4
    Et le champ "densite_rythmique_premier_plan" est numérique

  # réf: lyra-api/generation/ArrangementController.java:143 ; lyra-ml/app/main.py:3101 ; arrangement.py:2108-2113
  @AC-2 @api
  Plan du Scénario: Entrées invalides refusées (<cas>)
    Quand j'envoie POST "/api/arrange/deference-rythmique" avec le corps préparé pour le cas "<cas>"
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée

    Exemples:
      | cas                              |
      | premier plan vide                |
      | accompagnement vide              |
      | facteur 0                        |
      | facteur négatif                  |
      | facteur 1.5                      |
