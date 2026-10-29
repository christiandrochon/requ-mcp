# language: fr
@US-309 @REQ-309 @api
Fonctionnalité: Représenter une partition polyphonique multi-instruments validée (US-309)
  # REQ-309 - critères couverts à ce niveau : AC-1, AC-2, AC-3, AC-4
  # RÉSOLU (code) : partition d'essai = fixture issue de lyra-ml/tests/partition_exemples.py (chant, guitare 6 cordes, basse 4, batterie, … piano), schéma lyra-partition/1 ; /partition/midi renvoie les octets MIDI (audio/midi) ; /partition/musicxml renvoie { musicxml }.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: Partition multi-instruments avec guitare, basse et batterie : valide
    Quand j'envoie POST "/api/notation/partition/valider" avec la fixture "partition-exemple.json"
    Alors la réponse a le statut 200
    Et le champ "valide" vaut true

  @AC-1 @api
  Scénario: MusicXML : basse transposée d'une octave vers le bas, guitare en clef de sol 8vb sans transposition
    Quand j'envoie POST "/api/notation/partition/musicxml" avec la fixture "partition-exemple.json"
    Alors la réponse a le statut 200
    # Écart attendu : le conducteur est écrit en ut (musicxml.py:4), sans <transpose> ; l'AC (basse transposée) ne vaut que pour les parties séparées.
    Et le MusicXML de la réponse contient la partie "basse" avec un élément "<transpose>"
    Et le MusicXML de la réponse contient la partie "guitare" avec un élément "<clef-octave-change>-1</clef-octave-change>"
    Et le MusicXML de la réponse contient la partie "guitare" sans élément "<transpose>"

  @AC-1 @api
  Scénario: MIDI : la batterie est sur le canal 10
    Quand j'envoie POST "/api/notation/partition/midi" avec la fixture "partition-exemple.json"
    Alors la réponse a le statut 200
    Et le MIDI de la réponse place des notes sur le canal MIDI 10

  @AC-2 @api
  Scénario: Mesure incohérente : problème bloquant sans erreur HTTP
    Quand j'envoie POST "/api/notation/partition/valider" avec la fixture "partition-mesure-incoherente.json"
    Alors la réponse a le statut 200
    Et le champ "valide" vaut false
    Et un élément de "problemes" a "gravite" égal à "bloquant"
    Et la liste "problemes" contient un élément dont "partie_id" vaut "chant"
    Et la liste "problemes" contient un élément dont "mesure" vaut 0

  @AC-3 @api
  Scénario: Note hors tessiture : avertissement non bloquant
    Quand j'envoie POST "/api/notation/partition/valider" avec la fixture "partition-note-hors-tessiture.json"
    Alors la réponse a le statut 200
    Et le champ "valide" vaut true
    Et un élément de "problemes" a "gravite" égal à "avertissement"

  @AC-4 @api
  Scénario: Partition sans partie
    Quand j'envoie POST "/api/notation/partition/valider" avec la fixture "partition-sans-partie.json"
    Alors la réponse a le statut 200
    Et la liste "problemes" contient un élément dont "code" vaut "PARTITION_VIDE"

  @AC-4 @api
  Scénario: Partition sans aucune note
    Quand j'envoie POST "/api/notation/partition/valider" avec la fixture "partition-sans-note.json"
    Alors la réponse a le statut 200
    Et la liste "problemes" contient un élément dont "code" vaut "PARTITION_SANS_NOTE"
