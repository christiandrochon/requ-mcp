# language: fr
@api @US-108 @REQ-108
Fonctionnalité: Générer une mélodie inédite dans un mode, contrainte par les accords

  Contexte:
    Soit l'API Lyra joignable
    Et une grille de 4 mesures en 4/4 en "Ré" "dorien" (fixture "accords-4-mesures-re-dorien.json")

  # réf: lyra-api/generation/GenerationController.java:157 ; lyra-ml/app/main.py:1132 ; GenerationController.java:157 ; main.py:1132
  @AC-1 @api
  Scénario: La mélodie couvre exactement 4 mesures et reste dans le mode
    Quand j'envoie POST "/api/generate/melodie-inedite" avec la grille, "mode" "dorien", "tonique" "Ré", "nombre_mesures" 4, "metrique" "4/4" et "random_seed" 11
    Alors la réponse a le statut 200
    Et la somme des "duree_temps" de "result.motif" vaut 16
    Et toutes les notes de "result.motif" ont une classe de hauteur appartenant au mode dorien de Ré

  # réf: lyra-api/generation/GenerationController.java:157 ; lyra-ml/app/main.py:1132 ; refus HTTPException 422 main.py:1158
  @AC-2 @api
  Plan du Scénario: Une demande invalide est refusée (<cas>)
    Quand j'envoie POST "/api/generate/melodie-inedite" avec la grille ajustée selon le cas "<cas>"
    Alors la requête est refusée avec le statut 422

    Exemples:
      | cas                                              |
      | nombre_mesures absent                            |
      | nombre_mesures = 0                               |
      | nombre_mesures = -1                              |
      | accords ne couvrant que 3 mesures pour 4 demandées |

  # réf: lyra-api/generation/GenerationController.java:157 ; lyra-ml/app/main.py:1132 ; MelodieInediteResultDto.decisions ; DecisionAlternativeDto.java
  @AC-3 @api
  Scénario: Chaque note est accompagnée d'une décision listant les candidats rejetés avec leur poids
    Quand j'envoie POST "/api/generate/melodie-inedite" avec la grille, "mode" "dorien", "tonique" "Ré", "nombre_mesures" 4, "metrique" "4/4" et "random_seed" 11
    Alors la réponse a le statut 200
    Et "result.decisions" contient autant d'éléments que "result.motif"
    # RÉSOLU (code) : le poids est alternatives[].score (DecisionAlternative : value, score, raison_rejet).
    Et chaque élément de "result.decisions" a une liste "alternatives" dont chaque élément a "raison_rejet" non vide et "score" numérique
