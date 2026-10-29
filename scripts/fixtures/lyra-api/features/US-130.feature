# language: fr
@api @US-130 @REQ-130
Fonctionnalité: Fugue : sujet, réponse, contre-sujet, strette et analyse d'exposition

  Contexte:
    Soit l'API Lyra joignable
    Et un sujet de fugue en ré dorien : 62 64 65 67 69 67 65 64 (durées 1)

  # réf: lyra-api/generation/GenerationController.java:510 ; lyra-ml/app/main.py:1292 ; fugue.py:116-190
  @AC-1 @api
  Scénario: La réponse réelle est le sujet transposé exactement, durées inchangées
    Quand j'envoie POST "/api/generate/reponse-reelle" avec le sujet et "intervalle_transposition_demi_tons" 7
    Alors la réponse a le statut 200
    Et les hauteurs de "reponse" valent celles de "sujet" plus 7
    Et les durées de "reponse" sont celles de "sujet"

  # CONSTAT : classifier_reponse_sujet (analyse_fugue.py:91) n'est exposé par aucune route HTTP (grep main.py / AnalysisController.java) ;
  # le volet « l'analyse de fugue la classe réelle » du critère n'est pas vérifiable de bout en bout.
  @AC-1 @api @non-testable
  Scénario: L'analyse de fugue classe la réponse « reelle »
    # A CONFIRMER : aucune route
    Quand je demande la classification de la réponse par rapport au sujet
    Alors le type de réponse est "reelle"

  # réf: lyra-api/generation/GenerationController.java:522 ; lyra-ml/app/main.py:1309 lyra-api/generation/GenerationController.java:417 ; lyra-ml/app/main.py:1161 ; fugue.py:354-400
  @AC-2 @api
  Scénario: Le contre-sujet est identique au contrepoint de 1re espèce avec les mêmes paramètres, décisions persistées
    Quand j'envoie POST "/api/generate/contre-sujet" avec le sujet, "mode" "dorien", "tonique" "Ré", "au_dessus" true et "random_seed" 8
    Et j'envoie POST "/api/generate/contrepoint-premiere-espece" avec le sujet comme cantus firmus, "mode" "dorien", "tonique" "Ré", "au_dessus" true et "random_seed" 8
    Alors les "result.contrepoint" des deux réponses sont identiques
    Et le champ "requestId" de la réponse du contre-sujet est un UUID
    # RÉSOLU : vérification SQL directe sur generation_decision.
    Et la table "generation_decision" contient des lignes pour ce requestId

  # réf: lyra-api/generation/GenerationController.java:538 ; lyra-ml/app/main.py:3290 lyra-api/analysis/AnalysisController.java:273 ; lyra-ml/app/main.py:3305 ; motif.py:394-440, analyse_fugue.py:411-460
  @AC-3 @api
  Scénario: Une strette sans nombre d'entrées en contient 2 ; son analyse verticale ne persiste aucune décision
    Soit le nombre de lignes courant de la table "generation_decision"
    Quand j'envoie POST "/api/generate/stretto" avec le corps JSON :
      """
      {"sujet": [{"pitch":62,"duree_temps":1},{"pitch":64,"duree_temps":1},{"pitch":65,"duree_temps":1},{"pitch":67,"duree_temps":1},
                 {"pitch":69,"duree_temps":1},{"pitch":67,"duree_temps":1},{"pitch":65,"duree_temps":1},{"pitch":64,"duree_temps":1}]}
      """
    Alors la réponse a le statut 200
    Et la liste "voix" contient 2 éléments
    Quand j'envoie POST "/api/analyze/stretto-compatibilite-verticale" avec le corps de la réponse précédente
    Alors la réponse a le statut 200
    Et le champ "compatible" est booléen
    # RÉSOLU : vérification SQL directe sur generation_decision.
    Et le nombre de lignes de la table "generation_decision" est inchangé
