# language: fr
@api @US-116 @REQ-116
Fonctionnalité: Démarrer un morceau par un groove basse/batterie, section rythmique optionnelle

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:84 ; lyra-ml/app/main.py:1049 ; groove.py:76-111, generer_basse_pedale groove.py:840
  @AC-1 @api
  Scénario: Sans riff ni accords : coups de batterie et basse en pédale sur la tonique
    Quand j'envoie POST "/api/generate/groove" avec le corps JSON :
      """
      {"tempo_bpm": 120, "metrique": "4/4", "nombre_mesures": 4, "tonique": "Mi"}
      """
    Alors la réponse a le statut 200
    Et le champ "nombre_mesures" vaut 4
    Et la liste "batterie" n'est pas vide
    Et le "position_mesure" maximal de "batterie" vaut 4
    Et la liste "basse" n'est pas vide
    Et chaque élément de "basse" a "root_note" égal à "Mi"

  # réf: lyra-api/composition/CompositionController.java:217 ; lyra-ml/app/main.py:1731 (/compose/morceau-par-sections) ; demande.py:338-350 (batterie.type = "aucune"), CompositionController.java:217
  @AC-2 @api
  Scénario: Aucune piste de basse ou de batterie n'est ajoutée sans demande explicite
    Soit une demande de composition valide sans batterie ni instrument de basse (fixture "demande-composition-sans-batterie.json")
    Quand j'envoie POST "/api/composition/morceau-par-sections" avec cette demande
    Alors la réponse a le statut 200
    # PARTIEL : la demande doit être enveloppée {"demande": ...} (ControleFormeCorps ENVELOPPE) ; forme de la réponse relevée à l'exécution, absence de piste batterie/basse vérifiée par parcours des clés instrument/nom/type.
    Et le morceau obtenu ne contient aucune piste de batterie
    Et le morceau obtenu ne contient aucune piste de basse
