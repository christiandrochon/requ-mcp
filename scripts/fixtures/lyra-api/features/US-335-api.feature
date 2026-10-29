# language: fr
@US-335 @REQ-335 @api
Fonctionnalité: Générer avec le style statistique de son corpus personnel (US-335)
  # REQ-335 - critères couverts à ce niveau : AC-1, AC-2
  # RÉSOLU (code) : /api/generate/melodie-inedite { accords, mode, tonique, nombre_mesures, … } ; mode « éolien » (avec accent) ; indicateurs corpus_personnel_utilise / proportion_notes_influencees dans result (selon schéma).

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @AC-2 @api
  Scénario: Indicateurs d'influence du corpus personnel exposés et cohérents
    Quand j'envoie POST "/api/generate/melodie-inedite" avec le corps JSON :
      """
      {"accords": "@accords:ii,V,I,vi:4", "mode": "éolien", "tonique": "La", "nombre_mesures": 4, "random_seed": 5}
      """
    Alors la réponse a le statut 200
    Et les indicateurs d'influence du corpus personnel sont présents et cohérents
    # NON TESTÉ : « sans transition observée pour le mode : false et 0.0 » dépend de l'état du corpus personnel de la base (alimenté par les scénarios US-331) ; seule l'invariant utilise == (proportion > 0) est vérifié.
