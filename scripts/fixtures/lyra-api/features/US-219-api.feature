# language: fr
@US-219 @REQ-219 @api
Fonctionnalité: Demander une composition par émotions, intensités et sections (US-219)
  # REQ-219 - critères couverts à ce niveau : AC-5, AC-6
  # RÉSOLU (code) : /api/composition/demande/valider relaie lyra-ml ; une rubrique obligatoire manquante donne 422 {detail:[{loc, msg:"Champ obligatoire."}]}.

  Contexte:
    Soit l'API Lyra joignable

  @AC-5 @api
  Scénario: Rubrique obligatoire manquante à la composition : 422 « Champ obligatoire. » nommant la rubrique
    Quand j'envoie POST "/api/composition/morceau-par-sections" avec le corps JSON :
      """
      {"demande": {"schema_version": "lyra-composition-demande/1", "tempo_bpm": 120, "mode": "ionien", "tonique": "Do", "metrique": "4/4"}}
      """
    Alors la réponse a le statut 422
    Et le corps de la réponse contient "Champ obligatoire."
    Et le corps de la réponse contient "sections"

  # RÉSOLU (code) : la route de validation répond 200 { valide:false, problemes:[{rubrique, message}] } (pas 422) ; l'AC cite 422 : écart de route à arbitrer, voir rapport.
  @AC-5 @api
  Scénario: Rubrique obligatoire manquante à la validation : problème « Champ obligatoire. » nommant la rubrique
    Quand j'envoie POST "/api/composition/demande/valider" avec le corps JSON :
      """
      {"demande": {"schema_version": "lyra-composition-demande/1", "tempo_bpm": 120, "mode": "ionien", "tonique": "Do", "metrique": "4/4"}}
      """
    Alors la réponse a le statut 200
    Et le champ "valide" vaut false
    Et le corps de la réponse contient "Champ obligatoire."
    Et le corps de la réponse contient "sections"

  @AC-6 @api
  Scénario: Intensité hors 1..5 refusée avec un problème nommant l'intensité
    Quand j'envoie POST "/api/composition/demande/valider" avec le corps JSON :
      """
      {"demande": {"schema_version": "lyra-composition-demande/1", "tempo_bpm": 120, "mode": "ionien", "tonique": "Do", "metrique": "4/4", "emprunts": {"mode": "aucun", "dominantes_secondaires": false, "mediantes_chromatiques": false}, "melodie": {"type": "generee"}, "instruments": [{"instrument": "violon"}], "batterie": {"type": "aucune"}, "sections": [{"id": "s1", "nom": "A", "longueur_mesures": 4, "emotions": [{"emotion": "joie", "intensite": 6}]}], "graine": 1, "duree_totale_secondes": 8.0}}
      """
    Alors le champ "valide" vaut false
    Et le corps de la réponse contient "intensit"

  @AC-6 @api
  Scénario: Deux émotions sans emprunt refusées
    Quand j'envoie POST "/api/composition/demande/valider" avec le corps JSON :
      """
      {"demande": {"schema_version": "lyra-composition-demande/1", "tempo_bpm": 120, "mode": "ionien", "tonique": "Do", "metrique": "4/4", "emprunts": {"mode": "aucun", "dominantes_secondaires": false, "mediantes_chromatiques": false}, "melodie": {"type": "generee"}, "instruments": [{"instrument": "violon"}], "batterie": {"type": "aucune"}, "sections": [{"id": "s1", "nom": "A", "longueur_mesures": 4, "emotions": [{"emotion": "joie", "intensite": 3}, {"emotion": "tristesse", "intensite": 3}]}], "graine": 1, "duree_totale_secondes": 8.0}}
      """
    Alors le champ "valide" vaut false
