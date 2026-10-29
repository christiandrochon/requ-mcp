# language: fr
@api @US-100 @REQ-100
Fonctionnalité: Générer une progression d'accords à partir de paramètres

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:53 ; lyra-ml/app/main.py:1017
  @AC-1 @api
  Scénario: La progression en ré dorien commence et finit sur la tonique
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 120, "mode": "dorien", "tonique": "Ré", "nombre_mesures": 8, "metrique": "4/4", "random_seed": 42}
      """
    Alors la réponse a le statut 200
    Et le champ "result.nombre_mesures" vaut 8
    Et le champ "result.accords[0].degree_index" vaut 0
    Et le champ "result.accords[-1].degree_index" vaut 0
    Et le champ "result.accords[0].est_emprunt" vaut false
    Et le champ "result.accords[-1].est_emprunt" vaut false

  # réf: lyra-api/generation/GenerationController.java:53 ; lyra-ml/app/main.py:1017 ; champs : ChordDto.java:12-27
  @AC-2 @api
  Scénario: Chaque accord porte degré, chiffrage, notes, position, indicateur d'emprunt et justification
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 120, "mode": "dorien", "tonique": "Ré", "nombre_mesures": 8, "random_seed": 7}
      """
    Alors la réponse a le statut 200
    Et chaque élément de "result.accords" a les champs non nuls "degree_index, roman_numeral, notes, position_mesure, position_temps, est_emprunt, justification"
    Et chaque élément de "result.accords" a "justification" non vide
    Et chaque élément de "result.accords" où "est_emprunt" vaut true a "mode_source" non vide

  # réf: lyra-api/generation/GenerationController.java:53 ; lyra-ml/app/main.py:1017 ; refus Pydantic ChordProgressionRequest.tempo_bpm obligatoire (chord_progression.py:49)
  @AC-3 @api
  Scénario: Une requête sans tempo_bpm est refusée
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"mode": "dorien", "tonique": "Ré", "nombre_mesures": 8}
      """
    Alors la requête est refusée avec le statut 422
