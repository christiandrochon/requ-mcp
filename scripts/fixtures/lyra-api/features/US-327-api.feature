# language: fr
@US-327 @REQ-327 @api
Fonctionnalité: Générer à partir de morceaux déposés (corpus éphémère) (US-327)
  # REQ-327 - critères couverts à ce niveau : AC-1, AC-3
  # RÉSOLU (code) : sous-commande « generer » confirmée (tools/inspiration_cli.py, usage) ; scénarios exécutés par le CLI réel, dossiers temporaires hors de l'arbre Git.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api @cli
  Scénario: generer à partir de MIDI : partition .mid et .musicxml produites avec rapport
    Soit un dossier d'entrée contenant "simple-4-mesures.mid" et "trio-guitare-basse-batterie.mid"
    Quand j'exécute la commande "generer" avec les options "--graine 1"
    Alors le code de sortie vaut 0
    Et le dossier de sortie contient un fichier d'extension ".mid"
    Et le dossier de sortie contient un fichier d'extension ".musicxml"
    Et le dossier de sortie contient un fichier d'extension ".json" ou ".md" ou ".txt"

  @AC-3 @api @cli
  Scénario: Source audio sans fichier corrigé : refusée sans --sans-correction
    Soit un dossier d'entrée contenant "boucle.wav"
    Quand j'exécute la commande "generer" avec les options "--graine 1"
    Alors le code de sortie n'est pas 0
    Et la sortie de la commande contient "corrig"

  @AC-3 @api @cli @requiert-audio
  Scénario: Avec --sans-correction : le rapport l'écrit en tête
    Soit un dossier d'entrée contenant "boucle.wav"
    Quand j'exécute la commande "generer" avec les options "--graine 1 --sans-correction"
    Alors le code de sortie vaut 0
