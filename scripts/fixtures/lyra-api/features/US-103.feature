# language: fr
@api @US-103 @REQ-103
Fonctionnalité: Point de départ « aucune inspiration » : progression complète depuis un simple tempo

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:53 ; lyra-ml/app/main.py:1017 ; défauts DEFAULT_MODE modes.py:34, DEFAULT_TONIQUE chord_progression.py:37
  @AC-3 @api
  Scénario: Avec seulement tempo_bpm : 8 mesures en 4/4, mode éolien, tonique La
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 90}
      """
    Alors la réponse a le statut 200
    Et le champ "result.nombre_mesures" vaut 8
    Et le champ "result.metrique" vaut "4/4"
    Et le champ "result.mode" vaut "éolien"
    Et le champ "result.tonique" vaut "La"
    Et la liste "result.accords" n'est pas vide

  # réf: lyra-api/generation/GenerationController.java:53 ; lyra-ml/app/main.py:1017
  @AC-2 @api
  Scénario: Un mode fourni remplace le mode par défaut
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 90, "mode": "dorien"}
      """
    Alors la réponse a le statut 200
    Et le champ "result.mode" vaut "dorien"
    Et le champ "result.tonique" vaut "La"

  # réf: lyra-api/generation/GenerationController.java:53 ; lyra-ml/app/main.py:1017
  @AC-4 @api
  Scénario: Sans tempo_bpm la requête est refusée
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"mode": "dorien"}
      """
    Alors la requête est refusée avec le statut 422
