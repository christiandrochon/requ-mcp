# language: fr
@US-313 @REQ-313 @api
Fonctionnalité: Écouter un rendu audio de contrôle d'un motif (US-313)
  # REQ-313 - critères couverts à ce niveau : AC-1, AC-2, AC-3
  # CONSTAT d'environnement : fluidsynth et une banque de sons (FluidR3_GM.sf2) SONT installés sur la machine (contrairement au README env) : AC-1/AC-2 sont exécutés ; le cas « fluidsynth absent » est exclu.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @AC-2 @api
  Scénario: WAV base64 et instrument reconnu / inconnu
    Quand j'envoie POST "/api/audio/synthese-motif" avec le corps JSON :
      """
      {"notes": "@notes:60", "instrument": "flûte", "tempo_bpm": 120}
      """
    Alors la réponse a le statut 200
    Et le champ "audio_base64" décodé commence par "RIFF"
    Et le champ "duree_secondes" est supérieur à 0
    Et le champ "instrument_reconnu" vaut true
    Quand j'envoie POST "/api/audio/synthese-motif" avec le corps JSON :
      """
      {"notes": "@notes:60", "instrument": "instrument-inexistant", "tempo_bpm": 120}
      """
    Alors le champ "instrument_reconnu" vaut false
    Et le champ "programme_midi_gm" vaut 0

  @AC-3 @api
  Scénario: Motif sans note rejeté
    Quand j'envoie POST "/api/audio/synthese-motif" avec le corps JSON "{\"notes\": [], \"tempo_bpm\": 120}"
    Alors la requête est refusée par une erreur 4xx

  @AC-3 @api @requiert-env-sans-fluidsynth
  Scénario: FluidSynth absent : l'erreur nomme le paquet à installer
    Quand j'envoie POST "/api/audio/synthese-motif" avec le corps JSON :
      """
      {"notes": "@notes:60", "tempo_bpm": 120}
      """
    Alors la requête est refusée
    Et le corps de la réponse contient "fluidsynth"
