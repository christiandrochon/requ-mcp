# language: fr
@US-310 @REQ-310 @api
Fonctionnalité: Exporter une partition en MusicXML et en MIDI (US-310)
  # REQ-310 - critères couverts à ce niveau : AC-1, AC-2, AC-3
  # RÉSOLU (code) : POST /api/notation/partition/exporter écrit sous le stockage serveur et renvoie { fichiers:[{format, chemin_relatif, taille_octets}], avertissements } ; le contenu est contrôlé via /partition/musicxml et /partition/midi (mêmes moteurs, octets renvoyés). Pas de music21 côté test : lecture MIDI minimale.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @AC-2 @api
  Scénario: Export MusicXML et MIDI : fichiers listés avec chemin et taille
    Quand j'envoie POST "/api/notation/partition/exporter" avec la fixture "partition-exemple.json" et les champs :
      """
      {"formats": ["musicxml", "midi"]}
      """
    Alors la réponse a le statut 200
    Et la liste "fichiers" contient au moins 2 éléments
    Et chaque élément de la liste "fichiers" a un champ "chemin_relatif" non vide
    Et chaque élément de la liste "fichiers" a un champ numérique "taille_octets"

  @AC-1 @AC-2 @api
  Scénario: Le MIDI exporté compte les notes de la partition, avec la batterie sur le canal 10
    Quand j'envoie POST "/api/notation/partition/midi" avec la fixture "partition-exemple.json"
    Alors la réponse a le statut 200
    Et le MIDI de la réponse place des notes sur le canal MIDI 10
    Et le MIDI de la réponse utilise au moins 9 canaux ou pistes de notes

  @AC-3 @api
  Scénario: Partition invalide : 422 et message « Partition invalide »
    Quand j'envoie POST "/api/notation/partition/exporter" avec la fixture "partition-mesure-incoherente.json" et les champs :
      """
      {"formats": ["musicxml"]}
      """
    Alors la réponse a le statut 422
    Et le corps de la réponse contient "Partition invalide"
