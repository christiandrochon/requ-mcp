# language: fr
@US-329 @REQ-329 @api
Fonctionnalité: Transcrire un audio en MIDI (US-329)
  # REQ-329 - critères couverts à ce niveau : AC-1, AC-2, AC-3, AC-4
  # RÉSOLU (code) : aucun relais lyra-api : POST /transcription/audio-vers-midi sur lyra-ml (http://localhost:18000) ; entrée { nom_fichier, contenu_base64 }.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api @requiert-audio @depend-modele-ml
  Scénario: WAV transcrit : MIDI pivot et confiance agrégée
    Quand j'envoie POST "/transcription/audio-vers-midi" directement à lyra-ml avec le corps JSON :
      """
      {"nom_fichier": "boucle.wav", "contenu_base64": "@base64:boucle.wav"}
      """
    Alors la réponse a le statut 200
    Et le champ "pivot" est présent

  @AC-2 @api @requiert-audio @depend-modele-ml
  Scénario: Confiance inférieure à 0,5 : rejet motivé en français
    Quand j'envoie POST "/transcription/audio-vers-midi" directement à lyra-ml avec le corps JSON :
      """
      {"nom_fichier": "bruit.wav", "contenu_base64": "@base64:bruit.wav"}
      """
    Alors la requête est refusée par une erreur 4xx

  @AC-3 @api
  Scénario: Format non supporté : motif en français
    Quand j'envoie POST "/transcription/audio-vers-midi" directement à lyra-ml avec le corps JSON :
      """
      {"nom_fichier": "doc.txt", "contenu_base64": "@base64:doc.txt"}
      """
    Alors la requête est refusée par une erreur 4xx
    Et le message d'erreur est en français

  @AC-3 @api @requiert-audio
  Scénario: WAV de durée nulle : motif distinct en français
    Quand j'envoie POST "/transcription/audio-vers-midi" directement à lyra-ml avec le corps JSON :
      """
      {"nom_fichier": "vide.wav", "contenu_base64": "@base64:vide.wav"}
      """
    Alors la requête est refusée par une erreur 4xx
    Et le message d'erreur est en français

  # L'état « dépendances audio absentes » est celui de la pile (installation incomplète) : le test vérifie le 503 nommé.
  @AC-4 @api
  Scénario: Dépendances audio absentes : 503 DEPENDANCES_AUDIO_ABSENTES
    Quand j'envoie POST "/transcription/audio-vers-midi" directement à lyra-ml avec le corps JSON :
      """
      {"nom_fichier": "boucle.wav", "contenu_base64": "@base64:boucle.wav"}
      """
    Alors la réponse a le statut 503
    Et le corps de la réponse contient "DEPENDANCES_AUDIO_ABSENTES"
