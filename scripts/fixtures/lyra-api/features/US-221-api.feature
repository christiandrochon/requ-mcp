# language: fr
@US-221 @REQ-221 @api
Fonctionnalité: Composer à l'image avec timecodes et points de synchronisation (US-221)
  # REQ-221 - critères couverts à ce niveau : AC-4, AC-5, AC-6, AC-7
  # RÉSOLU (code) : le message V4 nomme les identifiants (« h1 », « h2 ») et non les libellés. /api/composition/morceau-par-sections renvoie { requestId, result.partition } (JSON) ; le MIDI s'obtient par POST /api/notation/partition/midi (octets, marqueur « HIT <libellé> <timecode> ecart … »).

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api
  Scénario: Marqueur texte HIT dans le MIDI exporté
    Quand j'envoie POST "/api/composition/morceau-par-sections" avec la fixture "demande-film-hit-porte-25fps.json"
    Alors la réponse a le statut 200
    Quand j'envoie POST "/api/notation/partition/midi" avec la partition "result.partition" de la réponse précédente
    Alors la réponse a le statut 200
    Et le corps de la réponse contient "HIT porte 00:05:00 ecart"

  @AC-5 @api
  Scénario: Deux hit points sur le même ancrage refusés
    Quand j'envoie POST "/api/composition/morceau-par-sections" avec la fixture "demande-film-hit-porte-25fps.json" dont la demande est complétée par :
      """
      {"hit_points": [{"id": "h1", "libelle": "porte", "timecode": "00:05:00", "ancrage": "debut_de_mesure", "ecart_accepte_secondes": 1.0}, {"id": "h2", "libelle": "fenetre", "timecode": "00:05:00", "ancrage": "debut_de_mesure", "ecart_accepte_secondes": 1.0}]}
      """
    Alors la réponse a le statut 422
    Et le corps de la réponse contient "h1"
    Et le corps de la réponse contient "h2"

  @AC-5 @api
  Scénario: Libellé vide refusé
    Quand j'envoie POST "/api/composition/morceau-par-sections" avec la fixture "demande-film-hit-porte-25fps.json" dont la demande est complétée par :
      """
      {"hit_points": [{"id": "h1", "libelle": "", "timecode": "00:05:00", "ancrage": "debut_de_mesure", "ecart_accepte_secondes": 1.0}]}
      """
    Alors la réponse a le statut 422

  @AC-5 @api
  Scénario: Identifiants de hit points en double refusés
    Quand j'envoie POST "/api/composition/morceau-par-sections" avec la fixture "demande-film-hit-porte-25fps.json" dont la demande est complétée par :
      """
      {"hit_points": [{"id": "h1", "libelle": "porte", "timecode": "00:05:00", "ancrage": "debut_de_mesure", "ecart_accepte_secondes": 1.0}, {"id": "h1", "libelle": "fenetre", "timecode": "00:07:00", "ancrage": "debut_de_mesure", "ecart_accepte_secondes": 1.0}]}
      """
    Alors la réponse a le statut 422

  @AC-5 @api
  Scénario: Timecode après la fin du morceau refusé
    Quand j'envoie POST "/api/composition/morceau-par-sections" avec la fixture "demande-film-hit-porte-25fps.json" dont la demande est complétée par :
      """
      {"hit_points": [{"id": "h1", "libelle": "porte", "timecode": "59:00:00", "ancrage": "debut_de_mesure", "ecart_accepte_secondes": 1.0}]}
      """
    Alors la réponse a le statut 422

  @AC-6 @api
  Scénario: Timecode avec images sans cadence refusé
    Quand j'envoie POST "/api/composition/synchronisation/analyser" avec le corps JSON :
      """
      {"tempo_bpm": 120, "metrique": "4/4", "sections": [{"id": "s1", "longueur_mesures": 8}], "hit_points": [{"id": "h1", "libelle": "porte", "timecode": "00:05:00", "ancrage": "debut_de_mesure"}], "duree_secondes": 16}
      """
    Alors la réponse a le statut 422

  @AC-6 @api
  Scénario: Numéro d'image égal à la cadence refusé
    Quand j'envoie POST "/api/composition/synchronisation/analyser" avec le corps JSON :
      """
      {"tempo_bpm": 120, "metrique": "4/4", "sections": [{"id": "s1", "longueur_mesures": 8}], "hit_points": [{"id": "h1", "libelle": "porte", "timecode": "00:05:25", "ancrage": "debut_de_mesure"}], "cadence": 25, "duree_secondes": 16}
      """
    Alors la réponse a le statut 422

  @AC-6 @api
  Scénario: Cadence non autorisée refusée
    Quand j'envoie POST "/api/composition/synchronisation/analyser" avec le corps JSON :
      """
      {"tempo_bpm": 120, "metrique": "4/4", "sections": [{"id": "s1", "longueur_mesures": 8}], "hit_points": [{"id": "h1", "libelle": "porte", "timecode": "00:05:00", "ancrage": "debut_de_mesure"}], "cadence": 29, "duree_secondes": 16}
      """
    Alors la réponse a le statut 422

  # RÉSOLU (code) : /analyze n'est pas strict (200 + statut « a_trancher ») ; V6/V7 sont levés par /morceau-par-sections (valider_demande en strict).
  @AC-7 @api
  Scénario: Écart hors tolérance sans acceptation refusé à la composition
    Quand j'envoie POST "/api/composition/morceau-par-sections" avec la fixture "demande-film-hit-porte-25fps.json" dont la demande est complétée par :
      """
      {"hit_points": [{"id": "h1", "libelle": "porte", "timecode": "00:05:00", "ancrage": "debut_de_mesure"}]}
      """
    Alors la réponse a le statut 422
    Et le corps de la réponse contient "écart"

  @AC-7 @api
  Scénario: Acceptation périmée refusée à la composition
    Quand j'envoie POST "/api/composition/morceau-par-sections" avec la fixture "demande-film-hit-porte-25fps.json" dont la demande est complétée par :
      """
      {"hit_points": [{"id": "h1", "libelle": "porte", "timecode": "00:05:00", "ancrage": "debut_de_mesure", "ecart_accepte_secondes": 0.5}]}
      """
    Alors la réponse a le statut 422
