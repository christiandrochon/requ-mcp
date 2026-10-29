# language: fr
@api @US-109 @REQ-109
Fonctionnalité: Améliorer une mélodie ou un riff existant avec variation motivée et expliquée

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/TransformController.java:68 ; lyra-ml/app/main.py:1541 ; amelioration_melodie.py:107-175 ; technique "fragmentation" motif.py:70
  @AC-1 @api
  Scénario: Le motif répétitif est amélioré par fragmentation
    Quand j'envoie POST "/api/transform/ameliorer-motif" avec le corps JSON :
      """
      {"motif": [{"pitch":60,"duree_temps":1},{"pitch":62,"duree_temps":1},{"pitch":64,"duree_temps":1},
                 {"pitch":65,"duree_temps":1},{"pitch":65,"duree_temps":1},{"pitch":65,"duree_temps":1},
                 {"pitch":65,"duree_temps":1},{"pitch":65,"duree_temps":1},{"pitch":65,"duree_temps":1}]}
      """
    Alors la réponse a le statut 200
    Et le champ "result.amelioration_trouvee" vaut true
    Et le champ "result.technique_retenue" vaut "fragmentation"
    Et les hauteurs de "result.motif_ameliore" valent [60, 62, 64, 65]
    Et le champ "result.justification" est non vide

  # réf: lyra-api/generation/TransformController.java:68 ; lyra-ml/app/main.py:1541
  @AC-2 @api
  Scénario: Un motif déjà propre est renvoyé inchangé
    Quand j'envoie POST "/api/transform/ameliorer-motif" avec le corps JSON :
      """
      {"motif": [{"pitch":60,"duree_temps":1},{"pitch":62,"duree_temps":1},{"pitch":64,"duree_temps":1},
                 {"pitch":65,"duree_temps":1},{"pitch":67,"duree_temps":1},{"pitch":65,"duree_temps":1},
                 {"pitch":64,"duree_temps":1},{"pitch":62,"duree_temps":1}]}
      """
    Alors la réponse a le statut 200
    Et le champ "result.amelioration_trouvee" vaut false
    Et les hauteurs de "result.motif_ameliore" valent [60, 62, 64, 65, 67, 65, 64, 62]
    # RÉSOLU (code) : l'indication est portée par justification (texte libre) ; l'oracle retenu est « justification non vide ».
    Et le champ "result.justification" est non vide

  # réf: lyra-api/generation/TransformController.java:68 ; lyra-ml/app/main.py:1541 ; amelioration_melodie.py:146-160
  @AC-3 @api
  Scénario: La réponse liste les candidats rejetés avec leur score
    Quand j'envoie POST "/api/transform/ameliorer-motif" avec le corps JSON :
      """
      {"motif": [{"pitch":60,"duree_temps":1},{"pitch":62,"duree_temps":1},{"pitch":64,"duree_temps":1},
                 {"pitch":65,"duree_temps":1},{"pitch":65,"duree_temps":1},{"pitch":65,"duree_temps":1},
                 {"pitch":65,"duree_temps":1},{"pitch":65,"duree_temps":1},{"pitch":65,"duree_temps":1}]}
      """
    Alors la réponse a le statut 200
    Et la liste "result.decision.alternatives" n'est pas vide
    Et chaque élément de "result.decision.alternatives" a "score" numérique et "raison_rejet" non vide
