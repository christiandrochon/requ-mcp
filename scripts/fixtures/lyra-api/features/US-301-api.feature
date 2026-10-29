# language: fr
@US-301 @REQ-301 @api
Fonctionnalité: Comparer la similarité structurelle de deux extraits (US-301)
  # REQ-301 - critères couverts à ce niveau : AC-1, AC-2, AC-3, AC-4

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: Progressions identiques : score 1
    Quand j'envoie POST "/api/compare/chord-progressions" avec le corps JSON :
      """
      {"accords_a": "@accords:I,IV,V,I", "accords_b": "@accords:I,IV,V,I"}
      """
    Alors la réponse a le statut 200
    Et le champ "score" vaut 1.0

  @AC-3 @api
  Scénario: Sans trigramme commun : score 0, points de divergence en phrases
    Quand j'envoie POST "/api/compare/chord-progressions" avec le corps JSON :
      """
      {"accords_a": "@accords:I,IV,V,I", "accords_b": "@accords:ii,vi,iii,vii°"}
      """
    Alors la réponse a le statut 200
    Et le champ "score" vaut 0.0
    Et la liste "points_divergence" n'est pas vide
    Et le champ "points_divergence[0]" contient "Divergence"

  @AC-2 @api
  Scénario: Motif transposé de +2 demi-tons : score 1
    Quand j'envoie POST "/api/compare/motifs" avec le corps JSON :
      """
      {"motif_a": "@notes:60,62,64,65", "motif_b": "@notes:62,64,66,67"}
      """
    Alors la réponse a le statut 200
    Et le champ "score" vaut 1.0

  @AC-4 @api @requiert-ollama
  Scénario: Compare avec un seul extrait : message explicite
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/nlu/command" avec le corps JSON "{\"texte\": \"compare ces deux progressions\", \"accordsExistants\": []}"
    Alors la réponse a le statut 200
    Et le champ "resultat" est non vide
