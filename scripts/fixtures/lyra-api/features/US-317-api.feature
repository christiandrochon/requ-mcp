# language: fr
@US-317 @REQ-317 @api
Fonctionnalité: Inclure les paroles dans la partition exportée (US-317)
  # REQ-317 - critères couverts à ce niveau : AC-1, AC-2, AC-3
  # RÉSOLU (code) : POST /api/notation/export { format, motif, paroles[], tempo_bpm, metrique, mode, tonique, voix_nommees, accords… } renvoie { musicxml } (lyra-ml /notation/export).

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: MusicXML avec une syllabe par note
    Quand j'envoie POST "/api/notation/export" avec le corps JSON :
      """
      {"format": "musicxml", "motif": "@notes:60,62,64", "paroles": ["Hel", "lo", "you"], "tempo_bpm": 100}
      """
    Alors la réponse a le statut 200
    Et le MusicXML de la réponse contient 3 éléments "<lyric"

  @AC-2 @api
  Scénario: Alignement paroles/notes incohérent : erreur, pas de MusicXML
    Quand j'envoie POST "/api/notation/export" avec le corps JSON :
      """
      {"format": "musicxml", "motif": "@notes:60,62,64", "paroles": ["Hel", "lo"], "tempo_bpm": 100}
      """
    Alors la requête est refusée par une erreur 4xx
    Et le corps de la réponse ne contient pas "<score-partwise"

  @AC-3 @api
  Scénario: Voix nommées avec paroles : paroles ignorées
    Quand j'envoie POST "/api/notation/export" avec le corps JSON :
      """
      {"format": "musicxml", "voix_nommees": [{"nom": "Soprano", "motif": "@notes:60,62,64"}], "paroles": ["Hel", "lo", "you"], "tempo_bpm": 100}
      """
    Alors la réponse a le statut 200
    Et le MusicXML de la réponse contient 0 éléments "<lyric"
