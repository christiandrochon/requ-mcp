# language: fr
@US-338 @REQ-338 @api
Fonctionnalité: Garder tout le calcul en local, sans service tiers (US-338)
  # REQ-338 - critères couverts à ce niveau : AC-3
  # Couper le réseau sortant exige des droits système (namespace/pare-feu) : hors périmètre ; le test vérifie seulement que les fonctions de calcul répondent (preuve nécessaire mais non suffisante).

  Contexte:
    Soit l'API Lyra joignable

  @AC-3 @api @non-deterministe-env
  Scénario: Fonctions de calcul sans Internet
    Quand j'envoie POST "/api/analyze/mode" avec le corps JSON :
      """
      {"accords": "@accords:ii,V,I,vi"}
      """
    Alors la réponse a le statut 200
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 110, "mode": "ionien", "tonique": "Do", "nombre_mesures": 4, "random_seed": 1}
      """
    Alors la réponse a le statut 200
