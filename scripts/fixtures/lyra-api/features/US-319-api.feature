# language: fr
@US-319 @REQ-319 @api
Fonctionnalité: Importer une partition de format courant avec rapport de pertes (US-319)
  # REQ-319 - critères couverts à ce niveau : AC-1, AC-2, AC-3
  # RÉSOLU (code) : POST /api/notation/ingestion/symbolique lit un chemin_relatif sous LYRA_DEPOT_RACINE (non défini sur la pile : @requiert-depot) ; la route /octets (fichier en corps) est exécutable et renvoie { musicxml, format, avertissements, resume }.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api @requiert-depot-racine
  Scénario: MIDI valide par chemin relatif : partition et rapport présents
    Quand j'envoie POST "/api/notation/ingestion/symbolique" avec le corps JSON "{\"chemin_relatif\": \"simple-4-mesures.mid\"}"
    Alors la réponse a le statut 200
    Et les champs "partition" et "rapport" sont tous présents à la racine

  @AC-1 @api
  Scénario: MIDI valide en octets : MusicXML produit et format détecté
    Quand j'envoie le fichier "simple-4-mesures.mid" en octets à "/api/notation/ingestion/symbolique/octets"
    Alors la réponse a le statut 200
    Et le champ "format" est non vide
    Et le MusicXML de la réponse contient 16 éléments "<pitch>"

  # AC-2 NON TESTÉ : aucune fixture produisant un élément non représentable (statut « a_corriger », rapport de pertes) n'a pu être établie ; la route /octets ne renvoie pas le rapport structuré.

  @AC-3 @api
  Scénario: Format non reconnu : refus en 415 ou 422 avec détail en français
    Quand j'envoie le fichier "illisible.bin" en octets à "/api/notation/ingestion/symbolique/octets"
    Alors la réponse a l'un des statuts 415, 422
    Et le message d'erreur est en français

  @AC-3 @api
  Scénario: Fichier sans aucune note refusé
    Quand j'envoie le fichier "sans-note.mid" en octets à "/api/notation/ingestion/symbolique/octets"
    Alors la réponse a le statut 422
    Et le message d'erreur est en français
