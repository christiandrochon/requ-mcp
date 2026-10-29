# language: fr
@US-223 @REQ-223 @api
Fonctionnalité: Proposer les instruments par section selon les émotions et les préférences du compositeur (US-223)
  # REQ-223 - critères couverts à ce niveau : AC-5, AC-6
  # RÉSOLU (code) : champ « preferences_non_couvertes » (liste de { emotion, cible, maniere, condition, approchant, citation }) par section (propositions.py:498) ; émotion « surprise » + batterie : préférence « cymbales » partielle (tests/test_propositions_preferences_c4b2.py).

  Contexte:
    Soit l'API Lyra joignable

  @AC-5 @api
  Scénario: preferences_non_couvertes présentes avec l'émotion de chaque préférence
    Quand j'envoie POST "/api/composition/sections/propositions-instruments" avec le corps JSON :
      """
      {"schema_version": "lyra-composition-propositions/1", "sections": [{"id": "s1", "nom": "A", "longueur_mesures": 4, "emotions": [{"emotion": "surprise", "intensite": 3}]}], "instruments": [{"instrument": "trompette (si♭)"}, {"instrument": "trombone ténor"}], "batterie_presente": true}
      """
    Alors la réponse a le statut 200
    Et la liste "sections[0].preferences_non_couvertes" n'est pas vide
    Et chaque élément de la liste "sections[0].preferences_non_couvertes" a un champ "emotion" non vide

  @AC-5 @api
  Scénario: preferences_non_couvertes absentes quand toutes les préférences sont couvertes
    Quand j'envoie POST "/api/composition/sections/propositions-instruments" avec le corps JSON :
      """
      {"schema_version": "lyra-composition-propositions/1", "sections": [{"id": "s1", "nom": "A", "longueur_mesures": 4, "emotions": [{"emotion": "joie", "intensite": 3}]}], "instruments": [], "batterie_presente": false}
      """
    Alors la réponse a le statut 200
    Et le champ "sections[0].preferences_non_couvertes" est absent

  @AC-6 @api
  Scénario: Statut des tables projet ou valide
    Quand j'envoie POST "/api/composition/sections/propositions-instruments" avec le corps JSON :
      """
      {"schema_version": "lyra-composition-propositions/1", "sections": [{"id": "s1", "nom": "A", "longueur_mesures": 4, "emotions": [{"emotion": "joie", "intensite": 3}]}], "instruments": [], "batterie_presente": false}
      """
    Alors le champ "statut_tables" est l'un de ["projet", "valide"]
