# language: fr
@api @US-118 @REQ-118
Fonctionnalité: Batterie calée sur un riff existant

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:84 ; lyra-ml/app/main.py:1049 ; groove.py:737-764, 767-813
  @AC-1 @api
  Scénario: Chaque coup de grosse caisse tombe sur un onset du riff
    Quand j'envoie POST "/api/generate/groove" avec le corps JSON :
      """
      {"tempo_bpm": 120, "metrique": "4/4", "nombre_mesures": 8,
       "riff": [{"pitch":40,"duree_temps":1},{"pitch":40,"duree_temps":0.5},{"pitch":43,"duree_temps":0.5},
                {"pitch":40,"duree_temps":2},{"pitch":45,"duree_temps":4}]}
      """
    Alors la réponse a le statut 200
    Et les positions (position_mesure, position_temps) des coups "kick" de "batterie" valent [(1,1.0),(1,2.0),(1,2.5),(1,3.0),(2,1.0)]

  # réf: lyra-api/generation/GenerationController.java:84 ; lyra-ml/app/main.py:1049 ; groove.py:759-763 (nombre de mesures sur la FIN de la dernière note)
  @AC-2 @api
  Scénario: Le riff impose la longueur : nombre_mesures est ignoré, même avec une dernière note tenue qui franchit la barre
    Quand j'envoie POST "/api/generate/groove" avec le corps JSON :
      """
      {"tempo_bpm": 120, "metrique": "4/4", "nombre_mesures": 8,
       "riff": [{"pitch":40,"duree_temps":4},{"pitch":43,"duree_temps":6}]}
      """
    Alors la réponse a le statut 200
    # 4 + 6 = 10 temps en 4/4 : la note tenue déborde sur la mesure 3
    Et le champ "nombre_mesures" vaut 3
    Et le "position_mesure" maximal de "batterie" vaut 3
    Et le "position_mesure" maximal de "basse" vaut 3

  # réf: lyra-api/generation/GenerationController.java:84 ; lyra-ml/app/main.py:1049 ; groove.py:786-810 (caisse claire et charleston génériques)
  @AC-3 @api
  Scénario: Caisse claire et charleston identiques avec ou sans riff (mêmes paramètres)
    Soit un riff de 2 mesures en 4/4 : "[{pitch:40,duree:4},{pitch:43,duree:4}]"
    Quand je demande un groove à 120 bpm, 4/4, 2 mesures, sans riff
    Et je demande le même groove avec ce riff
    Alors les coups "snare" des deux réponses sont identiques
    Et les coups "hihat" des deux réponses sont identiques
