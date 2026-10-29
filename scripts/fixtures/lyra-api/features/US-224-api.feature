# language: fr
@US-224 @REQ-224 @api
Fonctionnalité: Ouvrir une composition dans Composer, y importer une partition et revenir à la composition (US-224)
  # REQ-224 - critères couverts à ce niveau : AC-5, AC-6
  # RÉSOLU (code) : meta.import (nom, format, taille, sha256) est construit par le client Composer, pas par le serveur : le test envoie meta.import dans POST /api/pieces et vérifie sa relecture intacte (persistance serveur seulement).
  # RÉSOLU (code, babc922) : GP5 est désormais lu par alphaTab (lot 1 de l'ADR 0175, formats GP 6 à 8) : le refus GP5 de l'AC dépend de l'extension réelle ; pas de fixture GP5 produite ici.

  Contexte:
    Soit l'API Lyra joignable

  @AC-5 @api
  Scénario: Envoi d'un fichier MIDI valide : MusicXML renvoyé
    Quand j'envoie le fichier "simple-4-mesures.mid" en octets à "/api/notation/ingestion/symbolique/octets"
    Alors la réponse a le statut 200
    Et le champ "musicxml" est non vide
    Et le champ "format" est non vide

  @AC-5 @api
  Scénario: Pièce « editee » avec meta.import relue à l'identique
    Quand j'envoie POST "/api/pieces" avec le corps JSON :
      """
      {"titre": "import e2e", "contenu": "<score-partwise/>", "origine": "editee", "meta": {"import": {"nom": "simple.mid", "format": "midi", "taille": 128, "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"}}}
      """
    Alors la réponse a le statut 201
    Et je mémorise le champ "id" sous le nom "pieceId"
    Quand j'envoie GET "/api/pieces/{pieceId}"
    Alors la réponse a le statut 200
    Et le champ "origine" vaut "editee"
    Et le champ "meta.import.nom" vaut "simple.mid"
    Et le champ "meta.import.format" vaut "midi"
    Et le champ "meta.import.taille" vaut 128
    Et le champ "meta.import.sha256" est non vide

  @AC-6 @api
  Scénario: Corps de plus de 20 Mio refusé en 413
    Quand j'envoie un corps de 22020096 octets à "/api/notation/ingestion/symbolique/octets"
    Alors la réponse a le statut 413

  @AC-6 @api
  Scénario: Fichier MIDI corrompu refusé en 422 avec un détail en français
    Quand j'envoie le fichier "corrompu.mid" en octets à "/api/notation/ingestion/symbolique/octets"
    Alors la réponse a le statut 422
    Et le message d'erreur est en français

  @AC-6 @api
  Scénario: Fichier PDF refusé en 422
    Quand j'envoie le fichier "document.pdf" en octets à "/api/notation/ingestion/symbolique/octets"
    Alors la réponse a le statut 422
