# language: fr
@US-300 @REQ-300 @api
Fonctionnalité: Détecter la tonalité et le mode d'un extrait (US-300)
  # REQ-300 - critères couverts à ce niveau : AC-1, AC-2, AC-3

  Contexte:
    Soit l'API Lyra joignable

  # RÉSOLU (code) : modes = ionien, dorien, phrygien, lydien, mixolydien, eolien, locrien (MODE_INTERVALS, theory/analysis.py) ; réponse { meilleur{mode,tonique,score}, candidats_proches[] }.
  @AC-1 @api
  Scénario: Mode, tonique et confiance pour une progression
    Quand j'envoie POST "/api/analyze/mode" avec le corps JSON :
      """
      {"accords": "@accords:ii,V,I,vi"}
      """
    Alors la réponse a le statut 200
    Et le champ "meilleur.mode" est l'un de ["ionien", "dorien", "phrygien", "lydien", "mixolydien", "eolien", "locrien"]
    Et le champ "meilleur.tonique" est non vide
    Et le champ "meilleur.score" est numérique

  @AC-2 @api
  Scénario: Contenu ambigu : modes proches listés
    Quand j'envoie POST "/api/analyze/mode" avec le corps JSON :
      """
      {"accords": "@accords:ii,V,I,vi"}
      """
    Alors la réponse a le statut 200
    Et la liste "candidats_proches" n'est pas vide

  # La commande « analyse le mode » est classée par le modèle de langage local (Ollama) avant le routage.
  @AC-3 @api @requiert-ollama
  Scénario: Analyze sans contexte : message explicite
    Soit Ollama joignable avec le modèle de paroles configuré
    Quand j'envoie POST "/api/nlu/command" avec le corps JSON "{\"texte\": \"analyse le mode\"}"
    Alors la réponse a le statut 200
    Et le champ "resultat" est non vide

  @AC-1 @api
  Scénario: Corps sans accords refusé
    Quand j'envoie POST "/api/analyze/mode" avec le corps JSON "{}"
    Alors la requête est refusée par une erreur 4xx
